# Tag model
class Tag < ApplicationRecord
  belongs_to :user
  belongs_to :notebook
  has_many :subscriptions, as: :sub
  before_destroy  { |tag|
    subscriptions = Subscription.where(sub_type: "tag").where(sub_id: tag.id)
    tag = Tag.where(tag: tag.tag).where("id != ?",tag.id).first
    if(tag)
      subscriptions.each do |subscription|
        subscription.sub_id = tag.id
        subscription.save!
      end
    else
      subscriptions.destroy_all
    end
  }

  validates :tag, format: { with: /\A[a-z0-9-]+\z/, message: 'Tags can only use lowercase, digits and hyphens' }
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
        notebook&.tags&.find_by(tag: tag) ||
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
  def self.readable_by(user, tags = nil, show_deprecated = "false")
    notebooks = Notebook
      .readable_by(user)
      .joins('LEFT OUTER JOIN tags ON notebooks.id = tags.notebook_id')
    notebooks = notebooks.where('tag IN (?)', tags) if tags
    notebooks = notebooks.where("deprecated = False") unless show_deprecated == "true"
    notebooks
      .group(:tag)
      .count
      .reject {|tag, _count| tag.nil?}
  end

end
