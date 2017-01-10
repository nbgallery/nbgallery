# encoding: utf-8
require_relative './bit_matrix'

module MagicCloud
  # Pixel-by-pixel collision board
  #
  # Providen by width and height of the board, allows to check if given
  # shape (array of zero and non-zero pixels) "collides" with any of
  # previosly placed shapes
  class CollisionBoard < BitMatrix
    def initialize(width, height)
      super
      @rects = []
      @intersections_cache = {}
    end

    attr_reader :rects, :intersections_cache

    def criss_cross_collision?(rect)
      if rects.any?{|r| r.criss_cross?(rect)}
        Debug.stats[:criss_cross] += 1
        true
      else
        false
      end
    end

    def collides_previous?(shape, intersections)
      prev_idx = intersections_cache[shape.object_id]

      if prev_idx && (prev = intersections[prev_idx]) &&
         pixels_collision?(shape, prev)

        Debug.stats[:px_prev_yes] += 1
        true
      else
        false
      end
    end

    def pixels_collision_multi?(shape, intersections)
      intersections.each_with_index do |intersection, idx|
        next unless intersection
        next if idx == intersections_cache[shape.object_id] # already checked it

        next unless pixels_collision?(shape, intersection)

        Debug.stats[:px_yes] += 1
        intersections_cache[shape.object_id] = idx
        return true
      end

      false
    end

    def collides?(shape)
      Debug.stats[:collide_total] += 1

      # nothing on board - so, no collisions
      return false if rects.empty?

      # no point to try drawing criss-crossed words
      # even if they will not collide pixel-per-pixel
      return true if criss_cross_collision?(shape.rect)

      # then find which of placed sprites rectangles tag intersects
      intersections = rects.map{|r| r.intersect(shape.rect)}

      # no need to further check: this tag is not inside any others' rectangle
      if intersections.compact.empty?
        Debug.stats[:rect_no] += 1
        return false
      end

      # most probable that we are still collide with this word
      return true if collides_previous?(shape, intersections)

      # only then check points inside intersected rectangles
      return true if pixels_collision_multi?(shape, intersections)

      Debug.stats[:px_no] += 1

      false
    end

    def pixels_collision?(shape, rect)
      l, t = shape.left, shape.top
      (rect.x0...rect.x1).each do |x|
        (rect.y0...rect.y1).each do |y|
          dx = x - l
          dy = y - t
          return true if shape.sprite.at(dx, dy) && at(x, y)
        end
      end

      false
    end

    def add(shape)
      l, t = shape.left, shape.top
      shape.height.times do |dy|
        shape.width.times do |dx|
          put(l + dx, t + dy) if shape.sprite.at(dx, dy)
        end
      end

      rects << shape.rect
    end
  end
end
