# Tag model
class Tag < ApplicationRecord
  belongs_to :user
  belongs_to :notebook
  has_many :subscriptions, as: :sub
  before_destroy  { |tag|
    subscriptions = Subscription.where(sub_type: "tag").where(sub_id: tag.id)
    tag = Tag.where(tag: tag.tag_text).where("id != ?",tag.id).first
    if(tag)
      subscriptions.each do |subscription|
        subscription.sub_id = tag.id
        subscription.save!
      end
    else
      subscriptions.destroy_all
    end
  }

  validates :tag_text, format: { with: /\A[a-z0-9-]+\z/, message: 'Tags can only use lowercase, digits and hyphens' }
  validates :tag_text, :notebook, presence: true
  include ActiveModel::Validations
  validates_with RestrictedTagValidator

  include ExtendableModel

  def self.from_csv(str, opts={})
    user = opts[:user] || nil
    notebook = opts[:notebook] || nil
    if str.blank?
      []
    else
      begin
        str.parse_csv.reject(&:nil?).map(&:strip).uniq.map do |tag_text|
          # If the notebook already has the tag, keep the original
          # TODO: #360 - Fix when tag is normalized
          notebook&.tags&.find_by(tag: tag_text) ||
            Tag.new(tag: tag_text, user: user, notebook: notebook)
        end
      rescue CSV::MalformedCSVError => e
        raise Notebook::BadUpload.new("Unable to parse the tags you provided: #{e.message}")
      end
    end
  end

  def self.normalize(value)
    value&.strip&.downcase&.gsub(/[^a-z0-9-]/, '')
  end

  # TODO: #360 - Fix when tag is normalized
  def tag_text()
    return self.tag(true)
  end

  # TODO: #360 - Fix when tag is normalized
  def tag_text=(value)
    self.tag=(value)
  end

  # Stepping Stone for #360
  def tag(internal = false)
    begin
      raise unless internal
    rescue => e
      Rails.logger.warn("Accessing tags through Tag.tag is deprecated")
      Rails.logger.debug(e.backtrace.join "\n")
    end
    super()
  end

  # TODO: #360 - Fix when tag is normalized
  def tag=(value)
    # Normalize
    super(Tag.normalize(value))
  end

  # Hash of tag => number of readable notebooks.
  # Optional tags parameter to filter.
  # TODO: #360 - Fix when tag is normalized
  def self.readable_by(user, tags_text = nil, show_deprecated = "false")
    notebooks = Notebook
      .readable_by(user)
      .joins('LEFT OUTER JOIN tags ON notebooks.id = tags.notebook_id')
    notebooks = notebooks.where('tag IN (?)', tags_text) if tags_text
    notebooks = notebooks.where("deprecated = False") unless show_deprecated == "true"
    notebooks
      .group(:tag)
      .count
      .reject {|tag, _count| tag.nil?}
  end

end
