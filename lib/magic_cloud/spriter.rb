# encoding: utf-8
require_relative './bit_matrix'

module MagicCloud
  # Incapsulates sprite maker for any Shape, able to draw itself.
  class Spriter
    # Sprite is basically a 2-dimensional matrix of 1s and 0s,
    # representing "filled" and "empty" pixeslf of the shape to layout.
    class Sprite < BitMatrix
    end

    def make_sprites!(shapes)
      start = Time.now
      
      Debug.logger.info 'Starting sprites creation'
      
      restart_canvas!
      
      shapes.each do |shape|
        make_sprite(shape)
      end

      Debug.logger.info 'Sprites ready: %i sec, %i canvases' %
        [Time.now - start, Debug.stats[:canvases]]
    end

    private

    attr_reader :canvas, :cur_x, :cur_y, :row_height

    def make_sprite(shape)
      rect = shape.measure(canvas)
      ensure_position(rect)

      shape.draw(canvas, color: 'red', x: cur_x, y: cur_y)
      shape.sprite =
        pixels_to_sprite(
          canvas.pixels(cur_x, cur_y, rect.width, rect.height),
          rect
        )
          
      shift_position(rect)

      Debug.logger.debug 'Sprite for %p ready: %i×%i' %
        [shape, shape.sprite.width, shape.sprite.height]
    end

    CANVAS_SIZE = [1024, 1024]

    def restart_canvas!
      Debug.stats[:canvases] += 1
      @canvas = Canvas.new(*CANVAS_SIZE)
      @cur_x, @cur_y, @row_height = 0, 0, 0
    end

    # go to next free position after this rect was drawn
    def shift_position(rect)
      @cur_x += rect.width
      @row_height = [row_height, rect.height].max
    end

    # ensure this rect can be drawn at current position
    # or shift position of it can't
    def ensure_position(rect)
      # no place in current row -> go to next row
      if cur_x + rect.width > canvas.width
        @cur_x = 0
        @cur_y += row_height
        @row_height = 0
      end

      # no place in current canvas -> restart canvas
      restart_canvas! if cur_y + rect.height > canvas.height
    end

    def pixels_to_sprite(pixels, rect)
      sprite = Sprite.new(rect.width, rect.height)

      (0...rect.height).each do |y|
        (0...rect.width).each do |x|
          # each 4-th byte of RGBA - 1 or 0
          bit = pixels[(y * rect.width + x) * 4]
          sprite.put(x, y, bit.zero? ? 0 : 1)
        end
      end

      sprite
    end
  end
end
