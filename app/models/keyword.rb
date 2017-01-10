# Model for top notebook keywords
class Keyword < ActiveRecord::Base
  belongs_to :notebook

  include ExtendableModel

  #########################################################
  # Wordcloud methods
  #########################################################

  def self.wordcloud_image_file
    File.join(GalleryConfig.directories.wordclouds, 'keywords.png')
  end

  def self.wordcloud_map_file
    File.join(GalleryConfig.directories.wordclouds, 'keywords.map')
  end

  def self.wordcloud_exists?
    File.exist?(wordcloud_image_file) && File.exist?(wordcloud_map_file)
  end

  def self.wordcloud_map
    File.read(wordcloud_map_file) if File.exist?(wordcloud_map_file)
  end

  def self.generate_wordcloud
    counts = Keyword.group(:keyword).count
      .select {|keyword, _count| filter_for_wordcloud(keyword)}
      .sort_by {|_keyword, count| -count + rand}
    make_wordcloud(
      counts,
      'keywords',
      '/keywords/wordcloud.png',
      '/notebooks?q=%s&sort=score',
      width: 800,
      height: 600
    )
  end

  def self.filter_for_wordcloud(_tag)
    true
  end
end
