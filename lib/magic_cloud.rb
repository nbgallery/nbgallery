# encoding: utf-8

# Wordle-like word cloud main module
module MagicCloud
end

require_relative 'magic_cloud/cloud'


#######################################################################
# nbgallery modifications
#
# Everything below this point was added by nbgallery.
#
# We included the magic_cloud source directly because of dependency
# conflicts with slop, but we don't use the magic_cloud binary that
# requires slop.  Our only change to the magic_cloud source itself was
# requiring 'rmagick' instead of 'RMagick' in canvas.rb to resolve a
# deprecation warning.
#
# The magic_cloud code is available at https://github.com/zverok/magic_cloud
#
# The monkey patches below will work if you install magic_cloud from
# the gem. TODO: Clean up and submit upstream.
#######################################################################

# Monkey patch magic_cloud so we can make a clickable image map.
# See comments added inline.
# rubocop: disable Style/DotPosition, Style/NumericPredicate
module MagicCloud
  # :nodoc:
  class Cloud
    def monkey_draw(width, height)
      # FIXME: do it in init, for specs would be happy
      shapes = @words.each_with_index.map do |(word, size), i|
        Word.new(
          word,
          font_family: @options[:font_family] || DEFAULT_FAMILY,
          font_size: scaler.call(word, size, i),
          color: palette.call(word, i),
          rotate: rotator.call(word, i)
        )
      end

      Debug.reset!

      spriter = Spriter.new
      spriter.make_sprites!(shapes)

      layouter = Layouter.new(width, height)
      visible = layouter.layout!(shapes)

      canvas = Canvas.new(width, height, 'transparent')
      visible.each {|sh| sh.draw(canvas)}

      # Return value changed to return the shapes.
      [canvas.render, visible]
    end
  end

  # :nodoc:
  class Canvas
    def draw_text(text, options={})
      draw = Magick::Draw.new # FIXME: is it necessary every time?

      x = options.fetch(:x, 0)
      y = options.fetch(:y, 0)
      rotate = options.fetch(:rotate, 0)

      set_text_options(draw, options)

      rect = _measure_text(draw, text, rotate)

      draw.
        # Translate to the upper-left corner of the box.
        translate(x, y).

        # Uncomment these to draw the bounding box.
        #line(0, 0, rect.width, 0).
        #line(0, 0, 0, rect.height).
        #line(rect.width, 0, rect.width, rect.height).
        #line(0, rect.height, rect.width, rect.height).

        # Original - translate to midpoint of the box - text is centered.
        #translate(x + rect.width/2, y + rect.height/2). # original

        # For non-rotated boxes, text goes at
        #   x= midpoint of horizontal
        #   y= 1/4 box height above the bottom.
        # For rotated boxes, text goes at
        #   x= 1/4 box width right of the left wall (i.e. above the bottom, pre-rotation)
        #   y= midpoint of the vertical.
        # The 1/4 adjustment is to account for text that hangs below the line (descent).
        #   Note 1/4 is an approximation; it varies by font size something like .22 - .27.
        translate(
          rotate % 360 == 0 ? rect.width / 2 : rect.width / 4,
          rotate % 360 == 0 ? rect.height * 3 / 4 : rect.height / 2
        ).
        rotate(rotate).

        # Original - tweak (pre-rotated) vertical positioning - but the probelm here
        #   is that width and height of rect have already been adjusted for rotation, so
        #   when rotate==90, height is actually the pre-rotated *length* of the text,
        #   so height/8 is way too big of an adjustment.
        #translate(0, rect.height/8). # RMagick text_align seems really weird # original

        text(0, 0, text).
        draw(@internal)

      rect
    end

    def _measure_text(draw, text, rotate)
      # Original - changing the text like this adds way too much padding
      #metrics = draw.get_type_metrics('"' + text + 'm"')
      #w, h = rotated_metrics(metrics.width, metrics.height, rotate)

      # Our version - just add a few pixels of padding
      metrics = draw.get_type_metrics(text)
      height = metrics.ascent.abs + metrics.descent.abs + 4
      width = metrics.width + 4
      w, h = rotated_metrics(width, height, rotate)

      Rect.new(0, 0, w, h)
    end
  end
end
#rubocop: enable Style/DotPosition, Style/NumericPredicate

def make_wordcloud(words, name, img_src, url, opts={})
  st = Time.current
  opts = { width: 800, height: 600, limit: 150 }.merge(opts)
  output_dir = opts[:output_dir] || GalleryConfig.directories.wordclouds
  words = words.sort_by do |_word, count|
    -(count + (opts[:noise] == false ? 0 : rand))
  end.take(opts[:limit])
  cloud = MagicCloud::Cloud.new(words, scale: :sqrt)
  img, shapes = cloud.monkey_draw opts[:width], opts[:height]
  img.write File.join(output_dir, "#{name}.png")

  map = []
  map.push "<img src='#{img_src}' alt='#{name} word cloud' usemap='##{name}'/>"
  map.push "<map name='#{name}'>"
  shapes.sort_by {|shape| shape.width * shape.height}.each do |shape|
    next if shape.text.include? "'"
    map.push(
      "<area shape='rect' coords='#{shape.left},#{shape.top},#{shape.right},#{shape.bottom}'" \
      " href='#{url % shape.text}' alt='#{shape.text}' title='#{shape.text}'>"
    )
  end
  map.push '</map>'
  File.write File.join(output_dir, "#{name}.map"), map.join("\n")
  Rails.logger.info("Wordcloud #{name}: #{Time.current - st}")
end
