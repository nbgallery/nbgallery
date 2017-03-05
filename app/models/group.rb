# Group model
class Group < ActiveRecord::Base
  belongs_to :landing, class_name: 'Notebook'
  has_many :notebooks, as: :owner, dependent: :destroy
  has_many :membership, class_name: 'GroupMembership'
  has_many :users, through: :membership
  has_one :membership_creator, -> {where creator: true}, class_name: 'GroupMembership'
  has_one :creator, through: :membership_creator, class_name: 'User', source: :user
  has_many :membership_owners, -> {where owner: true}, class_name: 'GroupMembership'
  has_many :owners, through: :membership_owners, class_name: 'User', source: :user
  has_many :membership_editors, -> {where editor: true}, class_name: 'GroupMembership'
  has_many :editors, through: :membership_editors, class_name: 'User', source: :user

  validates :gid, :name, presence: true
  validates :gid, uniqueness: { case_sensitive: false }

  searchable do
    text :name
    text :description
  end

  # User-friendly URL /g/abcd1234/Partial-name-here
  def friendly_url
    GalleryLib.friendly_url('g', gid, name)
  end

  # Filter group-owned notebooks readable by user
  def notebooks_readable_by(user, use_admin=false)
    Notebook.readable_by(user, use_admin).where(owner: self)
  end

  # Return groups that have readable notebooks
  def self.readable_by(user, use_admin=false)
    counts = Notebook
      .readable_by(user, use_admin)
      .where(owner_type: 'Group')
      .group(:owner_id)
      .count
    Group
      .find(counts.keys)
      .map {|group| [group, counts[group.id]]}
      .to_h
  end
end
