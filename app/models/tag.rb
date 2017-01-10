# Tag model
class Tag < ActiveRecord::Base
  belongs_to :user
  belongs_to :notebook

  validates :tag, format: { with: /\A[a-z0-9-]+\z/, message: 'must be only lowercase, digits or hyphen' }
  validates :tag, :notebook, presence: true
  include ActiveModel::Validations
  validates_with RestrictedTagValidator

  include ExtendableModel

  def self.from_csv(str, opts={})
    user = opts[:user] || nil
    notebook = opts[:notebook] || nil
    if str.blank?
      []
    else
      str.parse_csv.reject(&:nil?).map(&:strip).uniq.map do |tag|
        # If the notebook already has the tag, keep the original
        (notebook && notebook.tags.find_by_tag(tag)) ||
          Tag.new(tag: tag, user: user, notebook: notebook)
      end
    end
  end

  def self.normalize(value)
    value&.strip&.downcase&.gsub(/[^a-z0-9-]/, '')
  end

  def tag=(value)
    # Normalize
    super(Tag.normalize(value))
  end

  # Hash of tag => number of readable notebooks.
  # Optional tags parameter to filter.
  def self.readable_by(user, tags=nil)
    notebooks = Notebook
      .readable_by(user)
      .joins('LEFT OUTER JOIN tags ON notebooks.id = tags.notebook_id')
    notebooks = notebooks.where('tag IN (?)', tags) if tags
    notebooks
      .group(:tag)
      .count
      .reject {|tag, _count| tag.nil?}
  end


  #########################################################
  # Wordcloud methods
  #########################################################

  def self.wordcloud_image_file
    File.join(GalleryConfig.directories.wordclouds, 'tags.png')
  end

  def self.wordcloud_map_file
    File.join(GalleryConfig.directories.wordclouds, 'tags.map')
  end

  def self.wordcloud_exists?
    File.exist?(wordcloud_image_file) && File.exist?(wordcloud_map_file)
  end

  def self.wordcloud_map
    File.read(wordcloud_map_file) if File.exist?(wordcloud_map_file)
  end

  def self.generate_wordcloud
    counts = Tag.group(:tag).count
      .select {|tag, _count| filter_for_wordcloud(tag)}
      .sort_by {|_tag, count| -count + rand}
    make_wordcloud(
      counts,
      'tags',
      '/tags/wordcloud.png',
      '/tags/%s',
      width: 640,
      height: 400
    )
  end

  def self.filter_for_wordcloud(_tag)
    true
  end
end
