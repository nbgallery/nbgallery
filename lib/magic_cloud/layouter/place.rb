# encoding: utf-8
module MagicCloud
  class Layouter
    class PlaceNotFound < RuntimeError
    end

    # Incapsulating place lookup process
    # 1. find initial random place
    # 2. at each step, shift in spiral from the previous place
    # 3. always knows, if the place "ready" for shape (empty and inside board)
    class Place
      def initialize(layouter, shape)
        @layouter, @shape = layouter, shape

        # initial position
        @start_x = (@layouter.width/2-@shape.width/2).to_i
        @start_y = (@layouter.height/2-@shape.height/2).to_i

        # when shift of position is more than max delta (diagonal of cloud)
        # there is no hope it will eventually found its place
        @max_delta = Math.sqrt(@layouter.width**2 + @layouter.height**2)

        # algo of next position calc
        @spiral = make_spiral(@shape.size)

        # direction of spiral
        @dt = rand < 0.5 ? 1 : -1 

        # initial point of time before we start to look for place
        @t = -@dt
      end

      def next!
        @t += @dt
        dx, dy = @spiral.call(@t)

        fail PlaceNotFound if [dx, dy].map(&:abs).min > @max_delta

        @shape.x = @start_x + dx
        @shape.y = @start_y + dy
      end

      def ready?
        !out_of_board? && !@layouter.board.collides?(@shape)
      end

      private

      def out_of_board?
        @shape.left < 0 || @shape.top < 0 ||
          @shape.right > @layouter.width || @shape.bottom > @layouter.height
      end

      # FIXME: now we always use "rectangular spiral"
      # d3.layout.cloud had two of them as an option - rectangular and
      # archimedean. I assume, it should be checked if usage of two
      # spirals produce significantly different results, and then
      # either one spiral should left, or it should became an option.
      def make_spiral(step)
        rectangular_spiral(step)
      end

      # rubocop:disable Metrics/AbcSize
      def archimedean_spiral(size)
        e = width / height
        ->(t){
          t1 = t * size * 0.01

          [
            e * t1 * Math.cos(t1),
            t1 * Math.sin(t1)
          ].map(&:round)
        }
      end

      def rectangular_spiral(size)
        dy = 4 * size * 0.1
        dx = dy * @layouter.width / @layouter.height
        x = 0
        y = 0
        ->(t){
          sign = t < 0 ? -1 : 1

          # zverok: this is original comment & code from d3.layout.cloud.js
          # Looks too witty for me.
          #
          # See triangular numbers: T_n = n * (n + 1) / 2.
          case (Math.sqrt(1 + 4 * sign * t) - sign).to_i & 3
          when 0 then x += dx
          when 1 then y += dy
          when 2 then x -= dx
          else        y -= dy
          end

          [x, y].map(&:round)
        }
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
