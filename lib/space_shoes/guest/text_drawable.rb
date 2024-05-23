# There are different ways to implement these tags. You can change the HTML tag (link,
# code, strong) or set default values (del for strikethrough.) There's no reason the
# Shoes tag name has to match the HTML tag (del, link). This can be a little
# complicated since CSS often sets default values (e.g. del for strikethrough) and
# Scarpe may use those default values or override them. Long term it may be easier
# for us to set up our own CSS for this somehow that does *not* use the HTML-tag
# defaults since the browser can mess with those, and there's no guarantee that
# Wasm uses the same default CSS style across all browsers.

module SpaceShoes
  # This class renders text tags like em, strong, link, etc.
  class TextDrawable < Drawable
    # Calzini renders based on properties, mostly Shoes styles.
    # To have Calzini render this for us, we convert to the format
    # Calzini expects and then let it render. See SpaceShoes::Para
    # for the specific Calzini call.
    def to_calzini_hash
      text_array = items_to_display_children(@text_items).map do |item|
        if item.respond_to?(:to_calzini_hash)
          item.to_calzini_hash
        elsif item.is_a?(String)
          item
        else
          # This should normally be filtered out in Lacci, long before we see it
          raise "Unrecognized item in TextDrawable! #{item.inspect}"
        end
      end

      {
        items: text_array,
        html_id: @linkable_id.to_s,
        tag: nil, # have Calzini assign a default unless a subclass overrides this
        props: shoes_styles,
      }
    end

    def element
      render("text_drawable", [to_calzini_hash])
    end

    def items_to_display_children(items)
      return [] if items.nil?

      items.map do |item|
        if item.is_a?(String)
          item
        else
          DisplayService.instance.query_display_drawable_for(item)
        end
      end
    end

    # Usually we query by ID, but for TextDrawable it has to be by class.
    # That's how needs_update!, etc continue to work.
    def html_element
      @elt_wrangler ||= WebWrangler::ElementWrangler.new(selector: %{document.getElementsByClassName("id_#{html_id}")}, multi: true)
    end
  end

  class << self
    def default_wasm_text_drawable_with_tag(shoes_tag, html_tag = nil)
      html_tag ||= shoes_tag
      wasm_class_name = shoes_tag.capitalize
      wasm_drawable_class = Class.new(SpaceShoes::TextDrawable) do
        class << self
          attr_accessor :html_tag
        end

        def to_calzini_hash
          h = super
          h[:tag] = self.class.html_tag
          h
        end
      end
      SpaceShoes.const_set wasm_class_name, wasm_drawable_class
      wasm_drawable_class.html_tag = html_tag
    end
  end
end

SpaceShoes.default_wasm_text_drawable_with_tag(:code)
SpaceShoes.default_wasm_text_drawable_with_tag(:del)
SpaceShoes.default_wasm_text_drawable_with_tag(:em)
SpaceShoes.default_wasm_text_drawable_with_tag(:strong)
SpaceShoes.default_wasm_text_drawable_with_tag(:span)
SpaceShoes.default_wasm_text_drawable_with_tag(:sub)
SpaceShoes.default_wasm_text_drawable_with_tag(:sup)
SpaceShoes.default_wasm_text_drawable_with_tag(:ins, "span") # Styled in Shoes, not CSS
