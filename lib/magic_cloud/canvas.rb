# encoding: utf-8
require 'rmagick'

module MagicCloud
  # Thin wrapper around RMagick, incapsulating ALL the real drawing.
  # As it's only class that "knows" about underlying graphics library,
  # it should be possible to replace it with another canvas with same
  # interface, not using RMagick.
  class Canvas
    def initialize(w, h, back = 'transparent')
      @width, @height = w, h
      @internal = Magick::Image.new(w, h){|i| i.background_color =  back}
    end

    attr_reader :internal, :width, :height

    RADIANS = Math::PI / 180

    def draw_text(text, options = {})
      draw = Magick::Draw.new # FIXME: is it necessary every time?
      
      x = options.fetch(:x, 0)
      y = options.fetch(:y, 0)
      rotate = options.fetch(:rotate, 0)

      set_text_options(draw, options)

      rect = _measure_text(draw, text, rotate)

      draw.
        translate(x + rect.width/2, y + rect.height/2).
        rotate(rotate).
        translate(0, rect.height/8). # RMagick text_align seems really weird
        text(0, 0, text).
        draw(@internal)

      rect
    end

    def measure_text(text, options)
      draw = Magick::Draw.new
      set_text_options(draw, options)
      _measure_text(draw, text, options.fetch(:rotate, 0))
    end

    def pixels(x, y, w, h)
      @internal.export_pixels(x, y, w, h, 'RGBA')
    end

    # rubocop:disable TrivialAccessors
    def render
      @internal
    end
    # rubocop:enable TrivialAccessors

    private

    def set_text_options(draw, options)
      draw.font_family = options[:font_family]
      draw.font_weight = Magick::NormalWeight
      draw.font_style = Magick::NormalStyle

      draw.pointsize = options[:font_size]
      draw.fill_color(options[:color])
      draw.gravity(Magick::CenterGravity)
      draw.text_align(Magick::CenterAlign)
    end

    def _measure_text(draw, text, rotate)
      metrics = draw.get_type_metrics('"' + text + 'm"')
      w, h = rotated_metrics(metrics.width, metrics.height, rotate)

      Rect.new(0, 0, w, h)
    end

    def rotated_metrics(w, h, degrees)
      radians = degrees * Math::PI / 180

      # FIXME: not too clear, just straightforward from d3.cloud
      sr = Math.sin(radians)
      cr = Math.cos(radians)
      wcr = w * cr
      wsr = w * sr
      hcr = h * cr
      hsr = h * sr

      w = [(wcr + hsr).abs, (wcr - hsr).abs].max.to_i
      h = [(wsr + hcr).abs, (wsr - hcr).abs].max.to_i

      [w, h]
    end
  end
end
