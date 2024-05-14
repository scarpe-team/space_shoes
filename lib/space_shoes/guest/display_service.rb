# frozen_string_literal: true

module SpaceShoes
  # This is a Scarpe DisplayService. It creates SpaceShoes drawables
  # corresponding to Shoes drawables, manages the DOM tree, and
  # generally keeps the Shoes/Wasm connection working.
  class DisplayService < Shoes::DisplayService
    include Shoes::Log

    class << self
      attr_accessor :instance
    end

    # The DocumentRoot is the top drawable of the Wasm-side drawable tree
    attr_reader :doc_root

    # app is the SpaceShoes display-side App
    attr_reader :app

    # wrangler is the SpaceShoes::WebWrangler, used for JS execution and handling the DOM
    attr_reader :wrangler

    # This is called before any of the various Drawables are created, to be
    # able to create them and look them up.
    def initialize
      if DisplayService.instance
        raise SpaceShoes::Error, "This is meant to be a singleton!"
      end

      DisplayService.instance = self

      super()
      log_init("SpaceShoes::DisplayService")
    end

    # Create a display drawable for a specific Shoes drawable, and pair it with
    # the linkable ID for this Shoes drawable.
    #
    # @param drawable_class_name [String] The class name of the Shoes drawable, e.g. Shoes::Button
    # @param drawable_id [String] the linkable ID for drawable events
    # @param properties [Hash] a JSON-serialisable Hash with the drawable's display properties
    # @param is_widget [Boolean] whether the class is a user-defined Shoes::Widget subclass
    # @param parent_id [Integer] the integer ID of the new drawable's parent
    # @return [Wasm::Drawable] the newly-created Wasm drawable
    def create_display_drawable_for(drawable_class_name, drawable_id, properties, is_widget:, parent_id:)
      existing = query_display_drawable_for(drawable_id, nil_ok: true)
      if existing
        @log.warn("There is already a display drawable for #{drawable_id.inspect}! Returning #{existing.class.name}.")
        return existing
      end

      if drawable_class_name == "App"
        unless @doc_root
          raise SpaceShoes::Errors::MissingDocRootError, "DocumentRoot is supposed to be created before App!"
        end

        display_app = SpaceShoes::App.new(properties)
        display_app.document_root = @doc_root
        #@control_interface = display_app.control_interface
        #@control_interface.doc_root = @doc_root
        #@app = @control_interface.app
        @wrangler = @control_interface.wrangler

        set_drawable_pairing(drawable_id, display_app)

        return display_app
      end

      # Create a corresponding display drawable
      if is_widget
        display_class = SpaceShoes::Flow
      else
        display_class = SpaceShoes::Drawable.display_class_for(drawable_class_name)
        unless display_class < SpaceShoes::Drawable
          raise SpaceShoes::Errors::BadDisplayClassType, "Wrong display class type #{display_class.inspect} for class name #{drawable_class_name.inspect}!"
        end
      end
      display_drawable = display_class.new(properties)
      set_drawable_pairing(drawable_id, display_drawable)
      if parent_id
        display_parent = query_display_drawable_for(parent_id, nil_ok: true)
        display_drawable.set_parent display_parent if display_parent
      end

      if drawable_class_name == "DocumentRoot"
        # DocumentRoot is created before App. Mostly doc_root is just like any other drawable,
        # but we'll want a reference to it when we create App.
        @doc_root = display_drawable
      end

      display_drawable
    end

    # Destroy the display service and the app. This isn't usually useful in Wasm.
    #
    # @return [void]
    def destroy
      @app.destroy
      DisplayService.instance = nil
    end
  end
end
