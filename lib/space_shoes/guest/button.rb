# frozen_string_literal: true

class SpaceShoes::Button < SpaceShoes::Drawable
  def initialize(properties)
    super

    # Bind to display-side handler for "click"
    bind("click") do
      # This will be sent to the bind_self_event in Button
      send_self_event(event_name: "click")
    end

    bind("hover") do
      send_self_event(event_name: "hover")
    end
  end

  def element
    render("button")
  end
end
