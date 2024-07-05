# frozen_string_literal: true

# The ControlInterface is used for testing. It's a way to register interest
# in important events like init and shutdown, and to configure a
# Shoes app for testing.
module SpaceShoes
  class ControlInterface
    include Shoes::Log

    SUBSCRIBE_EVENTS = [:init, :shutdown, :next_heartbeat, :every_heartbeat]
    DISPATCH_EVENTS = [:init, :shutdown, :heartbeat]
    INVALID_SYSTEM_COMPONENTS_MESSAGE = "Must pass non-nil app and wrangler to ControlInterface#set_system_components!"
    CONTROL_INTERFACE_INIT_MESSAGE = "ControlInterface code needs to be wrapped in handlers like on_event(:init) " +
      "to make sure they have access to app, doc_root, wrangler, etc!"

    attr_writer :doc_root
    attr_reader :do_shutdown

    class << self
      attr_accessor :instance
    end

    # The control interface needs to see major system components to hook into their events
    def initialize
      log_init("SpaceShoes::ControlInterface")

      if SpaceShoes::ControlInterface.instance
        raise Shoes::Errors::TooManyInstancesError, "Cannot create multiple SpaceShoes::ControlInterface objects!"
      end
      SpaceShoes::ControlInterface.instance = self

      @do_shutdown = false
      @event_handlers = {}
      (SUBSCRIBE_EVENTS | DISPATCH_EVENTS).each { |e| @event_handlers[e] = [] }
    end

    def inspect
      "<#ControlInterface>"
    end

    # This should get called once, from Shoes::App
    def set_system_components(app:, doc_root:, wrangler:)
      unless app
        @log.error("False app passed to set_system_components!")
        raise Scarpe::MissingAppError, INVALID_SYSTEM_COMPONENTS_MESSAGE
      end
      unless wrangler
        @log.error("False wrangler passed to set_system_components!")
        raise Scarpe::MissingWranglerError, INVALID_SYSTEM_COMPONENTS_MESSAGE
      end

      @app = app
      @doc_root = doc_root # May be nil at this point
      @wrangler = wrangler

      @wrangler.control_interface = self
    end

    def app
      raise Scarpe::MissingAppError, CONTROL_INTERFACE_INIT_MESSAGE unless @app

      @app
    end

    def doc_root
      raise Scarpe::MissingDocRootError, CONTROL_INTERFACE_INIT_MESSAGE unless @doc_root

      @doc_root
    end

    def wrangler
      raise Scarpe::MissingWranglerError, CONTROL_INTERFACE_INIT_MESSAGE unless @wrangler

      @wrangler
    end

    # The control interface has overrides for certain settings. If the override has been specified,
    # those settings will be overridden.

    # On recognised events, this sets a handler for that event
    def on_event(event, &block)
      unless SUBSCRIBE_EVENTS.include?(event)
        raise Scarpe::IllegalSubscribeEventError, "Illegal subscribe to event #{event.inspect}! Valid values are: #{SUBSCRIBE_EVENTS.inspect}"
      end

      @unsub_id ||= 0
      @unsub_id += 1

      @event_handlers[event] << { handler: block, unsub: @unsub_id }
      @unsub_id
    end

    # Send out the specified event
    def dispatch_event(event, *args, **keywords)
      @log.debug("CTL event #{event.inspect} #{args.inspect} #{keywords.inspect}")

      unless DISPATCH_EVENTS.include?(event)
        raise Scarpe::IllegalDispatchEventError, "Illegal dispatch of event #{event.inspect}! Valid values are: #{DISPATCH_EVENTS.inspect}"
      end

      if @do_shutdown
        @log.debug("CTL: Shutting down - not dispatching #{event}!")
        return
      end

      if event == :heartbeat
        dumb_dispatch_event(:every_heartbeat, *args, **keywords)

        # Next heartbeat is interesting. We can add new handlers
        # when dispatching a next_heartbeat handler. But we want
        # each handler to run only once.
        handlers = @event_handlers[:next_heartbeat]
        dumb_dispatch_event(:next_heartbeat, *args, **keywords)
        @event_handlers[:next_heartbeat] -= handlers
        return
      end

      if event == :shutdown
        @do_shutdown = true
      end

      dumb_dispatch_event(event, *args, **keywords)
    end

    private

    def dumb_dispatch_event(event, *args, **keywords)
      @event_handlers[event].each do |data|
        instance_eval(*args, **keywords, &data[:handler])
      end
    end
  end
end
