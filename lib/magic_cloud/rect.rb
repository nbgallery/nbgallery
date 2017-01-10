# encoding: utf-8
module MagicCloud
  # Utility geometrical rectangle, implementing arithmetic interactions
  # with other rectangles
  # (not to be confused with drawable shapes)
  class Rect
    def initialize(x0, y0, x1, y1)
      @x0, @y0, @x1, @y1 = x0, y0, x1, y1
    end

    attr_accessor :x0, :y0, :x1, :y1
    # NB: we are trying to use instance variables instead of accessors
    #     inside this class methods, because they are called so many
    #     times that accessor overhead IS significant.
    
    def width
      @x1 - @x0
    end

    def height
      @y1 - @y0
    end

    def collide?(other)
      @x1 > other.x0 &&
        @x0 < other.x1 &&
        @y1 > other.y0 &&
        @y0 < other.y1
    end

    # shift to new coords, preserving the size
    def move_to(x, y)
      @x1 += x - @x0
      @y1 += y - @y0
      @x0 = x
      @y0 = y
    end

    # rubocop:disable Metrics/AbcSize
    def adjust!(other)
      @x0 = other.x0 if other.x0 < @x0
      @y0 = other.y0 if other.y0 < @y0
      @x1 = other.x1 if other.x1 > @x1
      @y1 = other.y1 if other.y1 > @y1
    end
    # rubocop:enable Metrics/AbcSize

    def adjust(other)
      dup.tap{|d| d.adjust!(other)}
    end

    # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity,Metrics/AbcSize
    def criss_cross?(other)
      # case 1: this one is horizontal:
      # overlaps other by x, to right and left, and goes inside it by y
      @x0 < other.x0 && @x1 > other.x1 &&
        @y0 > other.y0 && @y1 < other.y1 ||
        # case 2: this one is vertical:
        # overlaps other by y, to top and bottom, and goes inside it by x
        @y0 < other.y0 && @y1 > other.y1 &&
          @x0 > other.x0 && @x1 < other.x1
    end
    # rubocop:enable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity,Metrics/AbcSize

    def intersect(other)
      # direct comparison is dirtier, yet significantly faster than
      # something like [@x0, other.x0].max
      ix0 = @x0 > other.x0 ? @x0 : other.x0
      ix1 = @x1 < other.x1 ? @x1 : other.x1
      iy0 = @y0 > other.y0 ? @y0 : other.y0
      iy1 = @y1 < other.y1 ? @y1 : other.y1

      if ix0 > ix1 || iy0 > iy1
        nil # rectangles are not intersected, in fact
      else
        Rect.new(ix0, iy0, ix1, iy1)
      end
    end

    def inspect
      "#<Rect[#{x0},#{y0};#{x1},#{y1}]>"
    end

    def to_s
      "#<Rect[#{x0},#{y0};#{x1},#{y1}]>"
    end
  end
end
