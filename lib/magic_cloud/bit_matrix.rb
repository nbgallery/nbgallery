# encoding: utf-8
module MagicCloud
  # Dead simple 2-dimensional "bit matrix", storing 1s and 0s.
  # Not memory effectife at all, but the fastest pure-Ruby solution
  # I've tried.
  class BitMatrix
    def initialize(width, height)
      @width, @height = width, height
      @bits = [0] * height*width
    end

    attr_reader :bits, :width, :height

    def put(x, y, px = 1)
      x < width or fail("#{x} outside matrix: #{width}")
      y < height or fail("#{y} outside matrix: #{height}")

      bits[y*@width + x] = 1 unless px == 0 # It's faster with unless
    end

    # returns true/false
    # FIXME: maybe #put should also accept true/false
    def at(x, y)
      bits[y*@width + x] != 0 # faster than .zero?
    end

    def dump
      (0...height).map{|y|
        (0...width).map{|x| at(x, y) ? ' ' : 'x'}.join
      }.join("\n")
    end
  end
end
