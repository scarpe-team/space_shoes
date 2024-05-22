# frozen_string_literal: true

module SpaceShoes
  class Arc < Drawable
    def element(&block)
      render("arc")
    end
  end

  class Arrow < Drawable
    def element(&block)
      render("arrow")
    end
  end

  class Line < Drawable
    def element(&block)
      render("line")
    end
  end

  class Rect < Drawable
    def element(&block)
      render("rect")
    end
  end

  class Star < Drawable
    def element(&block)
      render("star", &block)
    end
  end
end
