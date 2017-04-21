# Notebook model functionality
module Notebooks
  # Wordcloud functions for Notebooks
  module WordcloudFunctions
    extend ActiveSupport::Concern

    # Class-level wordcloud functions
    module ClassMethods
      # Generate all wordclouds
      def generate_all_wordclouds
        Notebook.find_each(&:generate_wordcloud)
      end
    end

    # Location on disk
    def wordcloud_image_file
      File.join(GalleryConfig.directories.wordclouds, "#{uuid}.png")
    end

    # Location on disk
    def wordcloud_map_file
      File.join(GalleryConfig.directories.wordclouds, "#{uuid}.map")
    end

    # Has the wordcloud been generated?
    def wordcloud_exists?
      File.exist?(wordcloud_image_file) && File.exist?(wordcloud_map_file)
    end

    # The raw image map from the file cache
    def wordcloud_map
      File.read(wordcloud_map_file) if File.exist?(wordcloud_map_file)
    end

    # Generate the wordcloud image and map
    def generate_wordcloud
      # Generating the cloud is slow, so only do it if the content
      # has changed OR we haven't regenerated it recently. (The top
      # keywords in theory could change as the whole corpus changes,
      # so we still want to occasionally regenerate the cloud.)
      need_to_regenerate =
        !File.exist?(wordcloud_image_file) ||
        File.mtime(wordcloud_image_file) < 7.days.ago ||
        File.mtime(wordcloud_image_file) < content_updated_at
      return unless need_to_regenerate
      kws = keywords.pluck(:keyword, :tfidf)
      return if kws.size < 2
      make_wordcloud(
        kws,
        uuid,
        "/notebooks/#{uuid}/wordcloud.png",
        '/notebooks?q=%s&sort=score',
        width: 320,
        height: 200,
        noise: false
      )
    end

    # Remove the files
    def remove_wordcloud
      [wordcloud_image_file, wordcloud_map_file].each do |file|
        File.unlink(file) if File.exist?(file)
      end
    end
  end
end
