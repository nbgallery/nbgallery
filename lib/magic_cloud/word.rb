# encoding: utf-8
require_relative './shape'

module MagicCloud
  # Class representing individual word in word cloud
  class Word < Shape
    def initialize(text, options)
      super()
      @text, @options = text.to_s, options
    end

    attr_reader :text, :options

    def size
      options[:font_size] # FIXME
    end

    def draw(canvas, opts = {})
      canvas.draw_text(text, @options.merge(x: x, y: y).merge(opts))
    end

    def measure(canvas)
      canvas.measure_text(text, @options)
    end

    def inspect
      "#<#{self.class} #{text}:#{options}>"
    end
  end
end
