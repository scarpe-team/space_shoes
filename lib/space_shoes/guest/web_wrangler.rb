# frozen_string_literal: true

require "cgi"
require_relative "wasm_calls"

# TODO: this can get simpler. What can we get rid of?
#
# * Can the is_running distinction go away or get simpler?
# * Can the ControlInterface go away and we'll just handle heartbeats here? Need to hook up app and wrangler somehow still

module SpaceShoes
  class WebWrangler
    include Shoes::Log

    class << self
      attr_accessor :instance
    end

    attr_reader :is_running
    attr_reader :is_terminated
    attr_reader :heartbeat # This is the heartbeat duration in seconds, usually fractional
    attr_reader :control_interface

    def initialize(title:, width:, height:, resizable: false, heartbeat: 0.1)
      log_init("SpaceShoes::WebWrangler")

      if SpaceShoes::WebWrangler.instance
        raise Shoes::Errors::TooManyInstancesError, "Cannot create multiple SpaceShoes::WebWrangler objects!"
      end
      SpaceShoes::WebWrangler.instance = self

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

      # Ruby receives scarpeHeartbeat messages via the window library's main loop.
      # So this is a way for Ruby to be notified periodically, in time with that loop.
      @wasm.bind("scarpeHeartbeat") do
        unless @control_interface.do_shutdown
          @heartbeat_handlers.each(&:call)
          @control_interface.dispatch_event(:heartbeat)
        end
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
        js_interval = (interval.to_f * 1_000.0).to_i
        code_str = "setInterval(#{name}, #{js_interval});"

        bind(name, &block)
        @wasm.eval(code_str)
      end
    end

    # Running callbacks

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
      @wasm.set_size(@width, @height, hint) # Currently a no-op
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
      item = JS.global[:document].getElementById("wrapper-wvroot")

      item[:innerHTML] = html_text
    end
  end
end

# Docs for ruby.wasm js gem:
# https://github.com/ruby/ruby.wasm/blob/main/packages/gems/js/lib/js.rb

class Scarpe::WebWrangler
  JS_NULL = JS.eval("null")

  # For now we don't need one of these to add DOM elements, just to manipulate them
  # after initial render.
  class ElementWrangler
    # Create an ElementWrangler for the given HTML ID or selector.
    # The caller should provide exactly one of the html_id or selector.
    #
    # @param html_id [String|NilClass] the HTML ID for the DOM element
    # @param selector [String|NilClass] the selector to get the DOM element(s)
    # @param multi [Boolean] whether the selector may return multiple DOM elements
    def initialize(html_id: nil, selector: nil, multi: false)
      @html_id = html_id
      @multi = multi
      @selector = selector
    end

    private

    def on_each(&block)
      if @multi
        items = JS.eval(@selector)
        items.each(&block)
      else
        item = JS.global[:document].getElementById(@html_id)
        yield(item) if item != JS_NULL
      end
    end

    public

    # Update the JS DOM element's value. The given Ruby value will be converted to string and assigned in backquotes.
    #
    # @param new_value [String] the new value
    # @return [nil]
    def value=(new_value)
      on_each { |item| item[:value] = new_value }
      nil
    end

    # Update the JS DOM element's inner_text. The given Ruby value will be converted to string and assigned in single-quotes.
    #
    # @param new_text [String] the new inner_text
    # @return [nil]
    def inner_text=(new_text)
      on_each { |item| item[:innerText] = new_text }
    end

    # Update the JS DOM element's inner_html. The given Ruby value will be converted to string and assigned in backquotes.
    #
    # @param new_html [String] the new inner_html
    # @return [nil]
    def inner_html=(new_html)
      on_each { |item| item[:innerHTML] = new_html }
    end

    # Update the JS DOM element's outer_html. The given Ruby value will be converted to string and assigned in backquotes.
    #
    # @param new_html [String] the new outer_html
    # @return [nil]
    def outer_html=(new_html)
      on_each { |item| item[:outerHTML] = new_html }
    end

    # Update the JS DOM element's attribute. The given Ruby value will be inspected and assigned.
    #
    # @param attribute [String] the attribute name
    # @param value [String] the new attribute value
    # @return [nil]
    def set_attribute(attribute, value)
      on_each { |item| item.call(:setAttribute, attribute, value) }
    end

    # Update an attribute of the JS DOM element's style. The given Ruby value will be inspected and assigned.
    #
    # @param style_attr [String] the style attribute name
    # @param value [String] the new style attribute value
    # @return [nil]
    def set_style(style_attr, value)
      on_each { |item| item[:style][style_attr] = value }
    end

    # Remove the specified DOM element
    #
    # @return [nil]
    def remove
      on_each(&:remove)
    end

    # Set an input checkbox to true or false
    #
    # @param mark [Boolean] whether to mark the checkbox true or false
    # @return [nil]
    def set_input_button(mark)
      checked_value = mark ? "true" : "false"
      on_each { |item| item[:checked] = checked_value }
    end
  end
end
