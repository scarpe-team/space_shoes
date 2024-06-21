# frozen_string_literal: true

module SpaceShoes
  class Radio < Drawable
    attr_reader :text

    def initialize(properties)
      super

      bind("click") do
        send_self_event(event_name: "click")
      end
    end

    def properties_changed(changes)
      items = changes.delete("checked")
      html_element.set_input_button(items)

      super
    end

    def element
      props = shoes_styles

      # If a group isn't set, default to the linkable ID of the parent slot
      unless @group
        props["group"] = @parent ? @parent.shoes_linkable_id : "no_group"
      end
      render("radio", props)
    end
  end
end
