# Helper functions used throughout the Gallery
module GalleryLib
  class << self
    # Is the string a uuid?
    def uuid?(str)
      /^[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$/.match(str)
    end

    # Clean a string for use in our user-friendly URLs
    def clean_str_for_url(str)
      str.scan(/[\w-]+/).join('-')[0...60]
    end

    # Generate a user-friendly URL
    def friendly_url(prefix, id, str)
      "/#{prefix}/#{uuid?(id) ? id[0...8] : id}/#{clean_str_for_url(str)}"
    end

    # Generate a user-friendly metrics URL
    def friendly_metrics_url(prefix, id, str)
      "/#{prefix}/#{uuid?(id) ? id[0...8] : id}/metrics/#{clean_str_for_url(str)}"
    end

    # Combine keyword blacklists into a set of terms
    def keyword_blacklist
      blacklist = Set.new(GalleryConfig.keywords.blacklisted)
      GalleryConfig.keywords.blacklists.each do |file|
        blacklist.merge(File.read(file).split)
      end
      blacklist
    end

    # Combine keyword whitelists into a set of terms
    def keyword_whitelist
      whitelist = Set.new(GalleryConfig.keywords.whitelisted)
      GalleryConfig.keywords.whitelists.each do |file|
        whitelist.merge(File.read(file).split)
      end
      whitelist
    end

    # Build list of extensions
    def extensions
      entries = {}
      GalleryConfig.directories.extensions.each do |dir|
        Dir["#{dir}/*"].each do |extension_dir|
          next unless File.directory?(extension_dir)
          # Must be a .rb file matching the directory name
          name = File.basename(extension_dir)
          rb_file = File.join(extension_dir, "#{name}.rb")
          next unless File.exist?(rb_file)

          # Must not be disabled
          if GalleryConfig.dig(:extensions, :disable, name)
            if defined?(Rails.logger) && Rails.logger
              Rails.logger.debug("Extension #{name} is disabled")
            else
              puts "Extension #{name} is disabled" # rubocop: disable Rails/Output
            end
            next
          end

          entries[name] = {
            name: name,
            dir: extension_dir,
            file: rb_file
          }

          # Does it include a config file?
          config = File.join(extension_dir, "#{name}.yml")
          entries[name][:config] = config if File.exist?(config)
        end
      end
      entries
    end
  end

  # Helper functions for notebook diffs
  module Diff
    # Stylesheet for diffs
    def self.css
      "<style type='text/css'>\n#{Diffy::CSS}\n</style>"
    end

    # Inline diff (like running diff -u)
    def self.inline(before, after)
      Diffy::Diff.new(before, after).to_s(:html)
    end

    # Side-by-side diff
    def self.split(before, after)
      diff = Diffy::SplitDiff.new(before, after, format: :html)

      # The diffs don't line up.  Walk the two sides and insert
      # blank lines to make them line up.
      begin
        left_in = diff.left.split("\n")
        right_in = diff.right.split("\n")
        left_out = []
        right_out = []
        left_pos = 0
        right_pos = 0
        loop do # rubocop: disable Metrics/BlockLength
          break if left_pos >= left_in.size or right_pos >= right_in.size
          #puts
          #puts "left=#{left_pos}/#{left_in.size} #{left_in[left_pos]}"
          #puts "right=#{right_pos}/#{right_in.size} #{right_in[right_pos]}"

          # First, regex to see if this is unchanged/insert/delete.
          # We should only get 'nil' at the same time when scanning
          # the header and trailer rows.
          left = /^ +<li class="([^"]+)">/.match left_in[left_pos]
          if left.nil?
            left_out.push left_in[left_pos]
            left_pos += 1
          end
          right = /^ +<li class="([^"]+)">/.match right_in[right_pos]
          if right.nil?
            right_out.push right_in[right_pos]
            right_pos += 1
          end
          next if left.nil? and right.nil?

          # Second, add blank lines if necessary
          #p [left[1], right[1]]
          case [left[1], right[1]]
          when %w[unchanged unchanged], %w[del ins], %w[ins del]
            # pass through and advance both sides
            left_out.push left_in[left_pos]
            left_pos += 1
            right_out.push right_in[right_pos]
            right_pos += 1
          when %w[unchanged del], %w[unchanged ins]
            # insert a blank on the left; advance the right
            left_out.push '    <li class="unchanged"><span> </span></li>'
            right_out.push right_in[right_pos]
            right_pos += 1
          when %w[del unchanged], %w[ins unchanged]
            # insert a blank on the right; advance the left
            left_out.push left_in[left_pos]
            left_pos += 1
            right_out.push '    <li class="unchanged"><span> </span></li>'
          else
            # shouldn't happen, but break to prevent infinite loop
            break
          end
        end

        # We should hit the end of both sides at the same time, but
        # if not, add the remainder back in.
        left_out += left_in[left_pos..-1] if left_pos != left_in.size
        right_out += right_in[right_pos..-1] if right_pos != right_in.size

        # Empty spans don't have the same height, so insert spaces.
        [left_out, right_out].each do |arr|
          arr.map! do |str|
            str.sub('<ins></ins>', '<ins> </ins>')
              .sub('<del></del>', '<del> </del>')
              .sub('<span></span>', '<span> </span>')
          end
        end
        [left_out.join("\n"), right_out.join("\n")]
      rescue #=> ex
        # If there's an error, just return the raw diff.
        #p ex
        [diff.left, diff.right]
      end
    end
    # rubocop: enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength

    # All the diff types together
    def self.all_the_diffs(before, after)
      diff = Diffy::Diff.new(before, after)
      {
        different: diff.count.positive?,
        css: css,
        inline: diff.to_s(:html),
        split: split(before, after)
      }
    end
  end
end
