# encoding: utf-8
require_relative './collision_board'

module MagicCloud
  # Main magic of magic cloud - layouting shapes without collisions.
  # Also, alongside with CollisionBoard -  the slowest and
  # algorithmically trickiest part.
  class Layouter
    def initialize(w, h, options = {})
      @board = CollisionBoard.new(w, h)

      @options = options
    end

    attr_reader :board

    def width
      board.width
    end

    def height
      board.height
    end

    def layout!(shapes)
      visible_shapes = []

      shapes.each do |shape|
        next unless find_place(shape)

        visible_shapes.push(shape)
      end

      visible_shapes
    end

    private

    def find_place(shape)
      place = Place.new(self, shape)
      start = Time.now
      steps = 0
      
      loop do
        steps += 1
        place.next!

        next unless place.ready?

        board.add(shape)
        Debug.logger.info 'Place for %p found in %i steps (%.2f sec)' %
          [shape, steps, Time.now-start]

        break
      end

      true
    rescue PlaceNotFound
      Debug.logger.warn 'No place for %p found in %i steps (%.2f sec)' %
        [shape, steps, Time.now-start]

      false
    end
  end
end

require_relative './layouter/place'
