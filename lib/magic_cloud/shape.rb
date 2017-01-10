# encoding: utf-8
module MagicCloud
  # Basic "abstract shape" class, with all primitive functionality
  # necessary for use it in Spriter and Layouter.
  #
  # Word for wordcloud is inherited from it, and its potentially
  # possible to inherit other types of shapes and layout them also.
  class Shape
    def initialize
      @x = 0
      @y = 0
      @sprite = nil
      @rect = nil
      @width = 0
      @height = 0
    end

    attr_reader :sprite, :x, :y, :width, :height, :rect

    def sprite=(sprite)
      @sprite = sprite
      @width = sprite.width
      @height = sprite.height
      @rect = Rect.new(left, top, right, bottom)
    end

    def x=(newx)
      @x = newx
      @rect.move_to(@x, @y)
    end

    def y=(newy)
      @y = newy
      @rect.move_to(@x, @y)
    end

    def left
      x
    end

    def right
      x + width
    end

    def top
      y
    end

    def bottom
      y + height
    end

    def draw(_canvas)
      fail NotImplementedError
    end
  end
end
