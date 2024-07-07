# frozen_string_literal: true

module SpaceShoes
  class App < Drawable
    attr_reader :control_interface

    attr_writer :shoes_linkable_id

    def initialize(properties)
      super

      @control_interface = ControlInterface.new

      # TODO: rename @view
      @view = WebWrangler.new title: @title,
        width: @width,
        height: @height,
        resizable: @resizable

      @callbacks = {}

      # The control interface has to exist to get callbacks like "override Scarpe app opts".
      # But the Scarpe App needs those options to be created. So we can't pass these to
      # ControlInterface.new.
      @control_interface.set_system_components app: self, doc_root: nil, wrangler: @view

      bind_shoes_event(event_name: "init") { init }
      bind_shoes_event(event_name: "run") { run }
      bind_shoes_event(event_name: "destroy") { destroy }

      # Run ShoesSpec tests on next heartbeat
      @control_interface.on_event(:next_heartbeat) do
        # If there's no error, this happens once. If an error is raised, keeps happening...

        ## Put the true/false pass/fail into a location where JS can access it
        e = Object.new # fake parallel executor
        def e.shutdown; end
        def e.start; end
        Minitest.parallel_executor = e # No threads available in ruby.wasm
        result = Minitest.run []
        # TODO: add a DOM element or similar so we know when this is complete
        JS.global[:document][:shoes_spec_passed] = result
        elt = JS.global[:document].createElement("div")
        elt[:className] = "minitest_result"
        test_details = ShoesSpec.test_class.results # Should only be one test class
        elt[:innerHTML] = "<p>#{result ? "passed" : "failed"}</p><p>#{test_details}</p>"
        JS.global[:document][:body].appendChild(elt)

        Shoes.APPS.each(&:destroy) # Need more recent version of Lacci with multi-app
      end
    end

    attr_writer :document_root

    def init
      scarpe_app = self

      @view.init_code("scarpeInit") do
        request_redraw!
      end

      @view.bind("scarpeHandler") do |*args|
        handle_callback(*args)
      end

      @view.bind("scarpeExit") do
        scarpe_app.destroy
      end
    end

    def run
      @control_interface.dispatch_event(:init)
      send_shoes_event("return", event_name: "custom_event_loop")

      @view.empty_page = empty_page_element

      @view.run
    end

    def destroy
      if @document_root || @view
        @control_interface.dispatch_event :shutdown
      end
      @document_root = nil
      if @view
        @view.destroy
        @view = nil
      end
    end

    # All JS callbacks to Scarpe drawables are dispatched
    # via this handler
    def handle_callback(name, *args)
      if @callbacks.key?(name)
        @callbacks[name].call(*args)
      else
        raise Scarpe::UnknownEventTypeError, "No such SpaceShoes callback: #{name.inspect}!"
      end
    end

    # Bind a Scarpe callback name; see handle_callback above.
    # See {Drawable} for how the naming is set up
    def bind(name, &block)
      @callbacks[name] = block
    end

    # Request a full redraw if Wasm is running. Otherwise
    # this is a no-op.
    #
    # @return [void]
    def request_redraw!
      wrangler = WebWrangler.instance
      if wrangler.is_running
        wrangler.replace(@document_root.to_html)
      end
      nil
    end
  end
end
