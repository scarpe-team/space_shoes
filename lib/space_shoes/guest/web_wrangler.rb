# frozen_string_literal: true

require "cgi"
require_relative "wasm_calls"

# TODO: this can get simpler. What can we get rid of?
#
# * Waiting changes
# * JS for DOM changes -- can use the ruby.wasm JS APIs
# * Can eval hook and EVAL_RESULT go away in favour of instantly running JS code?
# * Can js_wrapped_code go away?
# * Most of ElementWrangler and DOMWrangler?

module SpaceShoes
  class WebWrangler
    include Shoes::Log

    attr_reader :is_running
    attr_reader :is_terminated
    attr_reader :heartbeat # This is the heartbeat duration in seconds, usually fractional
    attr_reader :control_interface

    # This is the JS function name for eval results
    EVAL_RESULT = "scarpeAsyncEvalResult"

    # Allow a half-second for wasm to finish our JS eval before we decide it's not going to
    EVAL_DEFAULT_TIMEOUT = 0.5

    def initialize(title:, width:, height:, resizable: false, heartbeat: 0.1)
      log_init("SpaceShoes::WebWrangler")

      @log.debug("Creating WebWrangler...")

      @wasm = SpaceShoes::WasmCalls.new

      @title = title
      @width = width
      @height = height
      @resizable = resizable
      @heartbeat = heartbeat

      # Better to have a single setInterval than many when we don't care too much
      # about the timing.
      @heartbeat_handlers = []

      # Need to keep track of which wasm Javascript evals are still pending,
      # what handlers to call when they return, etc.
      @pending_evals = {}
      @eval_counter = 0

      @dom_wrangler = WebWrangler::DOMWrangler.new(self)

      @wasm.bind(EVAL_RESULT) do |*results|
        receive_eval_result(*results)
      end

      # Ruby receives scarpeHeartbeat messages via the window library's main loop.
      # So this is a way for Ruby to be notified periodically, in time with that loop.
      @wasm.bind("scarpeHeartbeat") do
        @heartbeat_handlers.each(&:call)
        @control_interface.dispatch_event(:heartbeat)
      end
      js_interval = (heartbeat.to_f * 1_000.0).to_i
      @wasm.init("setInterval(scarpeHeartbeat,#{js_interval})")
    end

    # Shorter name for better stack trace messages
    def inspect
      "SpaceShoes::WebWrangler:#{object_id}"
    end

    attr_writer :control_interface

    ### Setup-mode Callbacks

    def bind(name, &block)
      #raise Scarpe::JSBindingError, "App is running, javascript binding no longer works because it uses wasm init!" if @is_running

      @wasm.bind(name, &block)
    end

    def init_code(name, &block)
      raise Scarpe::JSInitError, "App is running, javascript init no longer works!" if @is_running

      # Save a reference to the init string so that it goesn't get GC'd
      code_str = "#{name}();"

      bind(name, &block)
      @wasm.init(code_str)
    end

    # Run the specified code periodically, every "interval" seconds.
    # If interface is unspecified, run per-heartbeat, which is very
    # slightly more efficient.
    def periodic_code(name, interval = heartbeat, &block)
      if interval == heartbeat
        @heartbeat_handlers << block
      else
        if @is_running
          # I *think* we need to use init because we want this done for every
          # new window. But will there ever be a new page/window? Can we just
          # use eval instead of init to set up a periodic handler and call it
          # good?
          raise Scarpe::PeriodicHandlerSetupError, "App is running, can't set up new periodic handlers with init!"
        end

        js_interval = (interval.to_f * 1_000.0).to_i
        code_str = "setInterval(#{name}, #{js_interval});"

        bind(name, &block)
        @wasm.init(code_str)
      end
    end

    # Running callbacks

    # js_eventually is a simple JS evaluation. On syntax error, nothing happens.
    # On runtime error, execution stops at the error with no further
    # effect or notification. This is rarely what you want.
    # The js_eventually code is run asynchronously, returning neither error
    # nor value.
    #
    # This method does *not* return a promise, and there is no way to track
    # its progress or its success or failure.
    def js_eventually(code)
      raise Scarpe::WebWranglerNotRunningError, "WebWrangler isn't running, eval doesn't work!" unless @is_running

      @wasm.eval(code)
    end

    # Eval a chunk of JS code asynchronously. This method returns a
    # promise which will be fulfilled or rejected after the JS executes
    # or times out.
    #
    # Note that we *both* care whether the JS has finished after it was
    # scheduled *and* whether it ever got scheduled at all. If it
    # depends on tasks that never fulfill or reject then it may wait
    # in limbo, potentially forever.
    #
    # Right now we can't/don't handle arguments from previous fulfilled
    # promises. To do that, we'd probably need to know we were passing
    # in a JS function.
    EVAL_OPTS = [:timeout, :wait_for]
    def eval_js_async(code, opts = {})
      @wasm.eval(code)
    end

    def self.js_wrapped_code(code, eval_id)
      <<~JS_CODE
        (function() {
          var code_string = #{JSON.dump code};
          try {
            result = eval(code_string);
            #{EVAL_RESULT}("success", #{eval_id}, result);
          } catch(error) {
            #{EVAL_RESULT}("error", #{eval_id}, error.message);
          }
        })();
      JS_CODE
    end

    private

    def receive_eval_result(r_type, id, val)
      entry = @pending_evals.delete(id)
      unless entry
        raise Scarpe::NonexistentEvalResultError, "Received an eval result for a nonexistent ID #{id.inspect}!"
      end

      @log.debug("Got JS value: #{r_type} / #{id} / #{val.inspect}")
    end

    public

    attr_writer :empty_page

    # After setup, we call run to go to "running" mode.
    # No more setup callbacks, only running callbacks.

    def run
      @log.debug("Run...")

      # 0 - Width and height are default size
      # 1 - Width and height are minimum bounds
      # 2 - Width and height are maximum bounds
      # 3 - Window size can not be changed by a user
      hint = @resizable ? 0 : 3

      @wasm.set_title(@title)
      @wasm.set_size(@width, @height, hint)
      @wasm.navigate("data:text/html, #{empty}")

      @is_running = true
      @wasm.run
    end

    def destroy
      @log.debug("Destroying WebWrangler...")
      @log.debug("  (WebWrangler was already terminated)") if @is_terminated
      @log.debug("  (WebWrangler was already destroyed)") unless @wasm
      if @wasm && !@is_terminated
        @bindings = {}
        @wasm.terminate
        @is_terminated = true
      end
    end

    private

    def empty
      Scarpe::Components::Calzini.empty_page_element
    end

    public

    # For now, the WebWrangler gets a bunch of fairly low-level requests
    # to mess with the HTML DOM. This needs to be turned into a nicer API,
    # but first we'll get it all into one place and see what we're doing.

    # Replace the entire DOM - return a promise for when this has been done.
    # This will often get rid of smaller changes in the queue, which is
    # a good thing since they won't have to be run.
    def replace(html_text)
      @dom_wrangler.request_replace(html_text)
    end

    # Request a DOM change - return a promise for when this has been done.
    def dom_change(js)
      @dom_wrangler.request_change(js)
    end

    # Return a promise that will be fulfilled when all current DOM changes
    # have committed (but not necessarily any future DOM changes.)
    def dom_redraw
      @dom_wrangler.redraw
    end

    # Return a promise which will be fulfilled the next time the DOM is
    # fully up to date. Note that a slow trickle of changes can make this
    # take a long time, since it is *not* only changes up to this point.
    # If you want to know that some specific change is done, it's often
    # easiest to use the promise returned by dom_change(), which will
    # be fulfilled when that specific change commits.
    def dom_fully_updated
      @dom_wrangler.fully_updated
    end

    def on_every_redraw(&block)
      @dom_wrangler.on_every_redraw(&block)
    end
  end
end

# Leaving DOM changes as "meh, async, we'll see when it happens" is terrible for testing.
# Instead, we need to track whether particular changes have committed yet or not.
# So we add a single gateway for all DOM changes, and we make sure its work is done
# before we consider a redraw complete.
#
# DOMWrangler batches up changes - it's fine to have a redraw "in flight" and have
# changes waiting to catch the next bus. But we don't want more than one in flight,
# since it seems like having too many pending RPC requests can crash wasm. So:
# one redraw scheduled and one redraw promise waiting around, at maximum.
module SpaceShoes
  class WebWrangler
    class DOMWrangler
      include Shoes::Log

      attr_reader :waiting_changes

      def initialize(web_wrangler, debug: false)
        log_init("WebWrangler::DOMWrangler")

        @wrangler = web_wrangler

        @waiting_changes = []

        # Initially we're waiting for a full replacement to happen.
        # It's possible to request updates/changes before we have
        # a DOM in place and before wasm is running. If we do
        # that, we should discard those updates.
        @first_draw_requested = false

        @redraw_handlers = []
      end

      def request_change(js_code)
        @log.debug("Requesting change with code #{js_code}")
        # No updates until there's something to update
        return unless @first_draw_requested

        @waiting_changes << js_code

        redraw
      end

      def self.replacement_code(html_text)
        "document.getElementById('wrapper-wvroot').innerHTML = `#{html_text}`; true"
      end

      def request_replace(html_text)
        @log.debug("Entering request_replace")
        # Replace other pending changes, they're not needed any more
        @waiting_changes = [DOMWrangler.replacement_code(html_text)]
        @first_draw_requested = true

        @log.debug("Requesting DOM replacement...")
        redraw
      end

      def on_every_redraw(&block)
        @redraw_handlers << block
      end

      def redraw
        @log.debug("Requesting redraw with #{@waiting_changes.size} waiting changes - scheduling a new redraw for them!")
        schedule_waiting_changes

        @redraw_handlers.each(&:call)
      end

      private

      # Put together the waiting changes into a new in-flight redraw request.
      # Return it as a promise.
      def schedule_waiting_changes
        return if @waiting_changes.empty?

        js_code = @waiting_changes.join(";")
        @waiting_changes = [] # They're not waiting any more!
        @wrangler.eval_js_async(js_code)
      end
    end
  end
end

# For now we don't need one of these to add DOM elements, just to manipulate them
# after initial render.
class Scarpe::WebWrangler
  class ElementWrangler
    attr_reader :html_id

    # Create an ElementWrangler for the given HTML ID or selector.
    # The caller should provide exactly one of the html_id or selector.
    #
    # @param html_id [String] the HTML ID for the DOM element
    def initialize(html_id: nil, selector: nil, multi: false)
      @webwrangler = SpaceShoes::DisplayService.instance.wrangler
      raise Scarpe::MissingWranglerError, "Can't get WebWrangler!" unless @webwrangler

      if html_id && !selector
        @selector = "document.getElementById('" + html_id + "')"
      elsif selector && !html_id
        @selector = selector
      else
        raise ArgumentError, "Must provide exactly one of html_id or selector!"
      end

      @multi = multi
    end

    private

    def on_each(fragment)
      if @multi
        @webwrangler.dom_change("a = Array.from(#{@selector}); a.forEach((item) => item#{fragment}); true")
      else
        @webwrangler.dom_change(@selector + fragment + ";true")
      end
    end

    public

    # Return a promise that will be fulfilled when all changes scheduled via
    # this ElementWrangler are verified complete.
    #
    # @return [Scarpe::Promise] a promise that will be fulfilled when scheduled changes are complete
    def promise_update
      @webwrangler.dom_promise_redraw
    end

    # Update the JS DOM element's value. The given Ruby value will be converted to string and assigned in backquotes.
    #
    # @param new_value [String] the new value
    # @return [Scarpe::Promise] a promise that will be fulfilled when the change is complete
    def value=(new_value)
      on_each(".value = `" + new_value + "`")
    end

    # Update the JS DOM element's inner_text. The given Ruby value will be converted to string and assigned in single-quotes.
    #
    # @param new_text [String] the new inner_text
    # @return [Scarpe::Promise] a promise that will be fulfilled when the change is complete
    def inner_text=(new_text)
      on_each(".innerText = '" + new_text + "'")
    end

    # Update the JS DOM element's inner_html. The given Ruby value will be converted to string and assigned in backquotes.
    #
    # @param new_html [String] the new inner_html
    # @return [Scarpe::Promise] a promise that will be fulfilled when the change is complete
    def inner_html=(new_html)
      on_each(".innerHTML = `" + new_html + "`")
    end

    # Update the JS DOM element's outer_html. The given Ruby value will be converted to string and assigned in backquotes.
    #
    # @param new_html [String] the new outer_html
    # @return [Scarpe::Promise] a promise that will be fulfilled when the change is complete
    def outer_html=(new_html)
      on_each(".outerHTML = `" + new_html + "`")
    end

    # Update the JS DOM element's attribute. The given Ruby value will be inspected and assigned.
    #
    # @param attribute [String] the attribute name
    # @param value [String] the new attribute value
    # @return [Scarpe::Promise] a promise that will be fulfilled when the change is complete
    def set_attribute(attribute, value)
      on_each(".setAttribute(" + attribute.inspect + "," + value.inspect + ")")
    end

    # Update an attribute of the JS DOM element's style. The given Ruby value will be inspected and assigned.
    #
    # @param style_attr [String] the style attribute name
    # @param value [String] the new style attribute value
    # @return [Scarpe::Promise] a promise that will be fulfilled when the change is complete
    def set_style(style_attr, value)
      on_each(".style.#{style_attr} = " + value.inspect + ";")
    end

    # Remove the specified DOM element
    #
    # @return [Scarpe::Promise] a promise that wil be fulfilled when the element is removed
    def remove
      on_each(".remove()")
    end

    def toggle_input_button(mark)
      checked_value = mark ? "true" : "false"
      on_each(".checked = #{checked_value}")
    end
  end
end
