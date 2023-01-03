# Group model
class Group < ApplicationRecord
  before_destroy { |group| Subscription.where(sub_type: "group").where(sub_id: group.id).destroy_all }
  # Landing page notebook for group view
  belongs_to :landing, class_name: 'Notebook', optional: true

  # Notebooks owned by this group
  has_many :notebooks, as: :owner, dependent: :destroy, inverse_of: 'owner'
  has_many :subscriptions, as: :sub, dependent: :destroy

  # Members
  has_many :membership, class_name: 'GroupMembership', dependent: :destroy, inverse_of: 'group'
  has_many :users, through: :membership, inverse_of: 'groups'

  after_save :index_group

  # Creator
  has_one(
    :membership_creator,
    -> {where creator: true},
    class_name: 'GroupMembership',
    inverse_of: 'group'
  )
  has_one(
    :creator,
    through: :membership_creator,
    class_name: 'User',
    source: :user,
    inverse_of: 'groups_creator'
  )

  # Owners
  has_many(
    :membership_owners,
    -> {where owner: true},
    class_name: 'GroupMembership',
    inverse_of: 'group'
  )
  has_many(
    :owners,
    through: :membership_owners,
    class_name: 'User',
    source: :user,
    inverse_of: 'groups_owner'
  )

  # Editors
  has_many(
    :membership_editors,
    -> {where editor: true},
    class_name: 'GroupMembership',
    inverse_of: 'group'
  )
  has_many(
    :editors,
    through: :membership_editors,
    class_name: 'User',
    source: :user,
    inverse_of: 'groups_editor'
  )

  validates :gid, :name, presence: true
  validates :gid, uniqueness: { case_sensitive: false }
  validates :name, length: { maximum: 100 }

  searchable :auto_index => false do
    text :name
    text :description
  end

# Failed to update the group
  class UpdateFailed < RuntimeError
  end

  #Handler to force index after save
  def index_group
    begin
      self.index
      Sunspot.commit
    rescue Exception => e
      Rails.logger.error("Solr is unreachable")
      Rails.logger.error(e)
    end
    return true
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end

  # Filter group-owned notebooks readable by user
  def notebooks_readable_by(user, use_admin=false)
    Notebook.readable_by(user, use_admin).where(owner: self)
  end

  # Return groups that have readable notebooks
  def self.readable_by(user, group_ids=nil, use_admin=false)
    counts = Notebook.readable_by(user, use_admin).where(owner_type: 'Group')
    counts = counts.where(owner_id: group_ids) if group_ids
    counts = counts.group(:owner_id).count
    Group
      .find(counts.keys)
      .map {|group| [group, counts[group.id]]}
      .to_h
  end

  include ExtendableModel

  def self.custom_simplify_email?(_group, _message)
    false
  end

  def simplify_email?(message)
    Group.custom_simplify_email?(self, message)
  end


end
