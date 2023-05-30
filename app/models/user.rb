# Gallery User model
class User < ApplicationRecord
  before_destroy  { |user|
    requests = ChangeRequest.where(reviewer_id: user.id)
    requests.each do |request|
      request.reviewer_id = nil
      request.save!
    end
  }
  before_destroy { |user| Commontator::Comment.where(creator: user.id).destroy_all }
  before_destroy { |user| Subscription.where(sub_type: "user").where(sub_id: user.id).destroy_all }
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :omniauthable, :timeoutable, :lockable
  has_one :preference, dependent: :destroy
  has_one :user_summary, dependent: :destroy, autosave: true
  has_one :user_preference, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_many :environments, dependent: :destroy
  has_many :notebooks, as: :owner, dependent: :destroy, inverse_of: 'owner'
  has_many(
    :notebooks_created,
    foreign_key: :creator_id,
    class_name: 'Notebook',
    dependent: :nullify,
    inverse_of: 'creator'
  )
  # Note: notebooks_updated only returns notebooks where user is *most recent* updater
  has_many(
    :notebooks_updated,
    foreign_key: :updater_id,
    class_name: 'Notebook',
    dependent: :nullify,
    inverse_of: 'updater'
  )
  has_many :tags, dependent: :nullify
  has_many :change_requests, foreign_key: 'requestor_id', dependent: :destroy, inverse_of: 'requestor'
  has_many :reviews, foreign_key: :reviewer_id, dependent: :nullify, inverse_of: 'reviewer'
  has_many :recommended_reviewers, dependent: :destroy
  has_many :recommended_reviews, through: :recommended_reviewers, source: :review
  has_many :clicks, dependent: :destroy
  has_many :clicks_90, -> {where('updated_at > ?', 90.days.ago)}, class_name: 'Click', inverse_of: 'user'
  has_many :stages, dependent: :destroy
  has_many :user_similarities, dependent: :destroy
  has_many :suggested_groups, dependent: :destroy
  has_many :suggested_tags, dependent: :destroy
  has_many :suggested_notebooks, dependent: :destroy
  has_many :feedbacks, dependent: :nullify
  has_many :resources, dependent: :nullify
  has_many :subscriptions, as: :sub, dependent: :destroy

  # Groups user belongs to
  has_many :group_membership, dependent: :destroy
  has_many :groups, through: :group_membership, inverse_of: 'users'

  # Groups owned
  has_many(
    :membership_owner,
    -> {where owner: true},
    class_name: 'GroupMembership',
    inverse_of: 'user'
  )
  has_many(
    :groups_owner,
    through: :membership_owner,
    class_name: 'Group',
    source: :group,
    inverse_of: 'owners'
  )

  # Groups with editor privileges
  has_many(
    :membership_editor,
    -> {where editor: true},
    class_name: 'GroupMembership',
    inverse_of: 'user'
  )
  has_many(
    :groups_editor,
    through:
    :membership_editor,
    class_name: 'Group',
    source: :group,
    inverse_of: 'editors'
  )

  # Groups created
  has_many(
    :membership_creator,
    -> {where creator: true},
    class_name: 'GroupMembership',
    inverse_of: 'user'
  )
  has_many(
    :groups_creator,
    through: :membership_creator,
    class_name: 'Group',
    source: :group,
    inverse_of: 'creator'
  )

  has_and_belongs_to_many :shares, class_name: 'Notebook', join_table: 'shares'
  has_and_belongs_to_many :stars, class_name: 'Notebook', join_table: 'stars'
  has_many :executions, dependent: :destroy
  has_many :execution_histories, dependent: :destroy
  has_many :revisions, dependent: :nullify # keep notebook revisions even if user is gone

  has_many :access_grants, class_name: 'Doorkeeper::AccessGrant', foreign_key: :resource_owner_id, dependent: :destroy # or :destroy if you need callbacks
  has_many :access_tokens, class_name: 'Doorkeeper::AccessToken', foreign_key: :resource_owner_id, dependent: :destroy # or :destroy if you need callbacks

  acts_as_commontator

  validates :password, confirmation: true # two fields should match
  validates :email, uniqueness: { case_sensitive: false }, presence: true
  validates(
    :user_name,
    uniqueness: true,
    allow_nil: true,
    format: { with: /\A[a-zA-Z][a-zA-Z0-9\-_@\.]*\z/ },
    exclusion: { in: %w[me] }
  )
  validates :email, email: true
  validate :email_in_allowed_domain

  scope :filter_by_user_name, -> (user_name) { where( "user_name like ?", "#{user_name}%" ) }
  scope :filter_by_first_name, -> (name) { where( "first_name like ?", "%#{name}%" ) }
  scope :filter_by_last_name, -> (name) { where( "last_name like ?", "%#{name}%" ) }
  scope :filter_by_org, -> (org) { where( "org like ?","%#{org}%" ) }
  scope :filter_by_approved, -> (approved) { where( "approved = ? or (approved IS NULL and 0 = ?)", approved, approved ) }
  scope :filter_by_admin, -> (admin) { where admin: admin }

  extend Forwardable

  def email_in_allowed_domain
    allowed_email_address = false
    allowed_domains = GalleryConfig.registration.allowed_domains
    allowed_email_address = true if allowed_domains.empty?
    allowed_domains&.each do |domain|
      allowed_email_address = true if email.end_with? domain
    end
    errors.add(:email, "#{email} is not in the list of allowed domains") unless allowed_email_address
  end

  # Constructor
  def initialize(*args, &block)
    super(*args, &block)
    self.preference = Preference.new(easy_buttons: true)
    self.user_summary = UserSummary.new
  end

  # Make sure preference always exists
  def preference
    pref = super
    pref || self.preference = Preference.new(easy_buttons: true)
  end

  # Make sure summary always exists
  def user_summary
    summary = super
    summary || self.user_summary = UserSummary.new
  end

  # User's full name
  def name
    if last_name.blank? && first_name.blank?
      user_name
    elsif last_name.blank?
      first_name
    else
      "#{first_name} #{last_name}"
    end
  end

  def to_param
    user_name ? "#{id}-#{user_name}" : id.to_s
  end

  include ExtendableModel

  #########################################################
  # Authentication stuff
  #########################################################

  # Is this a user with an account?
  # In practice this also means "logged in"
  def member?
    !id.nil?
  end

  # User needs to be logged in
  class NotAuthorized < RuntimeError
  end

  # User doesn't have permission
  class Forbidden < RuntimeError
  end

  # User didn't accept terms of service
  class MustAcceptTerms < RuntimeError
  end

  # User's profile is incomplete
  class MissingRequiredFields < RuntimeError
  end

  #########################################################
  # Group methods
  #########################################################

  # Return group-ids from the user's groups
  def group_gids
    groups.map(&:gid)
  end

  # Return whether the user is in the group with the given id
  def in_group?(group_or_gid)
    if group_or_gid.is_a?(Group)
      groups.include?(group_or_gid)
    else
      group_gids.include?(group_or_gid)
    end
  end

  # Return whether user owns a group
  def group_owner?(group_or_gid)
    if group_or_gid.is_a?(Group)
      groups_owner.include?(group_or_gid)
    else
      groups_owner.map(&:gid).include?(group_or_gid)
    end
  end

  # Return whether user can edit notebooks in a group
  def group_editor?(group_or_gid)
    if group_or_gid.is_a?(Group)
      groups_editor.include?(group_or_gid)
    else
      groups_editor.map(&:gid).include?(group_or_gid)
    end
  end

  # Returns an array of Groups that the user is a member of, and the number of notebooks in that group
  def groups_with_notebooks
    counts = Notebook.readable_by(self).where(owner: groups).group(:owner_id).count
    groups
      .map {|group| [group, counts.fetch(group.id, 0)]}
      .reject {|_group, count| count.zero?}
  end

  #########################################################
  # Notebook permission methods
  #########################################################

  # Return all notebooks the user can view
  def readable_notebooks(page=1)
    Notebook.paginate(page: page, per_page: @per_page).readable_by(self)
  end

  # Return all notebooks the user can edit
  def editable_notebooks(page=1)
    Notebook.paginate(page: page, per_page: @per_page).editable_by(self)
  end

  # Return whether user can edit the given notebook
  def can_edit?(notebook, use_admin=false)
    # Note that the custom check can override ownership
    return false unless notebook.custom_edit_check(self, use_admin)
    notebook.owner == self ||
      groups_editor.include?(notebook.owner) ||
      shares.include?(notebook) ||
      (use_admin && admin?)
  end

  # Return whether user can view the given notebook
  def can_read?(notebook, use_admin=false)
    # Note that the custom check can override ownership
    return false unless notebook.custom_read_check(self, use_admin)
    notebook.public ||
      can_edit?(notebook, use_admin) ||
      groups.include?(notebook.owner) ||
      (use_admin && admin?)
  end

  def owner(notebook)
    if notebook != nil
      type = Notebook.find(notebook.id).owner_type
      if ((type == "User" && notebook.owner_id == id) || (type == "Group" && GroupMembership.where(user_id: id, group_id: Group.find(notebook.owner_id)).map(&:owner)[0]) || admin?)
        return true
      end
    else
      return false
    end
  end

  # Return whether use could view the given revision, considered in isolation.
  # Note, though, that users can only see revisions back to the most recent one
  # they can't, so this should not be used in the UI for a direct check.
  # Instead see Notebook#revision_list
  def can_read_revision?(revision, use_admin=false)
    # Note that the custom check can override ownership
    return false unless revision.custom_read_check(self, use_admin)
    # Notebook owners can see all revisions
    return true if can_edit?(revision.notebook) || groups.include?(revision.notebook.owner)
    # Was the notebook was public at the time the revision was made?
    revision.public
  end

  # Return whether the user can view the notebook ONLY because of admin
  def privileged_on?(notebook)
    admin? && !can_read?(notebook)
  end


  #########################################################
  # Notebook helpers
  #########################################################

  # Return viewable notebooks with a specific tag
  # TODO: #360 - Fix when tag is normalized
  def readable_notebooks_with_tag(tag_text, page=1)
    readable_notebooks(page)
      .joins('LEFT OUTER JOIN tags ON tags.notebook_id = notebooks.id')
      .where('tags.tag = ?', tag_text)
  end

  # Return viewable notebooks with tag 'buildingblocks'
  def buildingblocks(page=1)
    readable_notebooks_with_tag('buildingblocks', page)
  end

  # Return viewable notebooks with tag 'trusted'
  def trusted(page=1)
    readable_notebooks_with_tag('trusted', page)
  end

  def change_requests_pending
    if member?
      ChangeRequest.all_change_requests(self).where(notebook_id: Notebook.editable_by(self).map(&:id), status: "pending")
    else
      []
    end
  end

  def change_requests_owned
    if member?
      ChangeRequest.all_change_requests(self).where(notebook_id: Notebook.editable_by(self).map(&:id))
    else
      []
    end
  end

  #########################################################
  # Click helpers
  #########################################################

  # Delegate methods to summary object
  UserSummary.attribute_names.each do |name|
    next if name == 'id' || name.end_with?('_id', '_at')
    def_delegator :user_summary, name.to_sym, name.to_sym
  end

  def recent_updates
    clicks
      .includes(:notebook)
      .where(action: ['created notebook', 'updated notebook'])
      .order(updated_at: :desc)
  end

  def recent_actions
    clicks
      .includes(:notebook)
      .where.not(action: 'agreed to terms')
      .order(updated_at: :desc)
  end

  def users_of_notebooks(options={})
    # Number of users of this user's notebooks.  Get *all* public notebooks this
    # user has created, but restrict usage to the date range.
    min_date = options[:min_date]
    max_date = options[:max_date]
    notebook_ids = options[:notebook_ids] || notebooks_created.where(public: true).map(&:id)
    return 0 if notebook_ids.blank?
    actions = ['ran notebook', 'downloaded notebook', 'executed notebook']
    users = Click.where(action: actions).where(notebook_id: notebook_ids)
    users = apply_date_range(users, min_date, max_date)
    users.select(:user_id).distinct.count
  end

  def health_bonus(notebook_ids)
    return 0 if notebook_ids.blank?
    NotebookSummary
      .where(notebook_id: notebook_ids)
      .map(&:health)
      .select {|h| Notebook.health_symbol(h) == :healthy}
      .map {|h| 10.0 * h}
      .reduce(0, :+)
  end

  def notebook_action_list(options={})
    min_date = options[:min_date]
    max_date = options[:max_date]
    # User's public created notebooks, ignoring date range
    all_public_nbs = notebooks_created.where(public: true).map {|nb| [nb.id, nb]}.to_h
    # Hash of [nb id, action, user id] => count
    actions = apply_date_range(Click, min_date, max_date, 'clicks.updated_at')
      .where(notebook_id: all_public_nbs.keys)
      .where("(action != 'agreed to terms' AND action NOT LIKE '%change request%')")
      .group(:notebook_id, :action, :user_id)
      .count
    # Hash of notebook => thing => count
    actions = actions
      .group_by {|stuff, _count| stuff[0]}
      .map do |nb_id, stuffs|
        users = Set.new
        counts = {}
        stuffs.each do |stuff, count|
          users.add(stuff[2])
          counts[stuff[1]] = count
        end
        counts['users'] = users.count
        [all_public_nbs[nb_id], counts]
      end
    actions.to_h
  end

  # Hash of action => count of unique notebooks, within the date range
  def action_counts(min_date, max_date)
    apply_date_range(clicks, min_date, max_date, 'clicks.updated_at')
      .joins(:notebook)
      .select('action, COUNT(DISTINCT notebooks.id) AS count')
      .group(:action)
      .map {|e| [e.action, e.count]}
      .to_h
  end

  # Hash of review type => count for reviews completed in the date range
  def review_counts(min_date, max_date)
    apply_date_range(reviews, min_date, max_date)
      .where(status: 'completed')
      .group(:revtype)
      .count
  end

  # Updates to notebooks created by others
  def updates_to_others(min_date, max_date)
    apply_date_range(clicks, min_date, max_date, 'clicks.updated_at')
      .joins(:notebook)
      .where(action: 'edited notebook')
      .where('notebooks.creator_id != clicks.user_id')
      .select('notebooks.id')
      .distinct
      .count
  end

  # Number of notebooks the user provided feedback on
  def feedback_count(min_date, max_date)
    apply_date_range(feedbacks, min_date, max_date).select(:notebook_id).distinct.count
  end

  # Number of notebooks the user commented on
  def comment_count(min_date, max_date)
    apply_date_range(comments, min_date, max_date).select(:thread_id).distinct.count
  end

  def notebook_action_counts(options={})
    min_date = options[:min_date]
    max_date = options[:max_date]
    actions = action_counts(min_date, max_date)
    reviews = review_counts(min_date, max_date)
    # IDs of user's public created notebooks, ignoring date range
    all_public_ids = notebooks_created.where(public: true).map(&:id)
    # User's public created notebooks, within the date range
    public_nbs = apply_date_range(notebooks_created.where(public: true), min_date, max_date, 'created_at')

    # Counts
    results = {
      view: actions['viewed notebook'] || 0,
      run: actions['ran notebook'] || 0,
      execute: actions['executed notebook'] || 0,
      download: actions['downloaded notebook'] || 0,
      create: actions['created notebook'] || 0,
      create_public: public_nbs.count,
      langs: public_nbs.select(:lang).distinct.count,
      edit: actions['edited notebook'] || 0,
      users: users_of_notebooks(options.merge(notebook_ids: all_public_ids)),
      health_bonus: health_bonus(all_public_ids),
      technical_reviews: reviews['technical'] || 0,
      functional_reviews: reviews['functional'] || 0,
      edit_other: updates_to_others(min_date, max_date),
      feedbacks: feedback_count(min_date, max_date),
      comments: comment_count(min_date, max_date)
    }
    results
  end


  #########################################################
  # Recommendation helpers
  #########################################################

  def similar_users
    user_similarities
      .includes(:other_user)
      .order(score: :desc)
  end

  # Feature vector to compare with other users
  def feature_vector
    @feature_vector ||= clicks_90
      .select("notebook_id, SUM(IF(action='executed notebook',1.0,0.5)) AS score")
      .group(:notebook_id)
      .map {|e| [e.notebook_id, e.score.to_f]}
      .to_h
  end

  # Consider someone "new" if they haven't looked at many notebooks
  def newish_user
    feature_vector.size <= 3
  end

  # Compute recommendations for this user
  def compute_recommendations
    return unless member?
    SuggestedNotebook.compute_for(self)
    SuggestedGroup.compute_for(self)
    SuggestedTag.compute_for(self)
  end

  # Recommended notebooks filtered by readability and deduped.
  # Not to be confused with #suggested_notebooks, which is a
  # direct join to the suggestion table without filter/dedupe.
  def notebook_recommendations(allow_run=true)
    # Compute on the fly in case the cron hasn't run for a new user
    compute_recommendations if allow_run && newish_user && suggested_notebooks.count.zero?

    # Return recommendations filtered for readability
    Notebook.readable_megajoin(self).order('score DESC').having('reasons IS NOT NULL')
  end

  # Recommended groups with number of readable notebooks
  def group_recommendations(allow_run=true)
    # Compute on the fly in case the cron hasn't run for a new user
    compute_recommendations if allow_run && newish_user && suggested_groups.count.zero?

    # Return hash of Group objects => number of readable notebooks
    suggested = Group.find(suggested_groups.map(&:group_id))
    counts = Notebook.readable_by(self).where(owner: suggested).group(:owner_id).count
    suggested
      .map {|group| [group, counts.fetch(group.id, 0)]}
      .reject {|_group, count| count.zero?}
      .sort_by {|_group, count| -count + rand}
  end

  # Recommended tags with number of readable notebooks
  def tag_recommendations(allow_run=true)
    # Compute on the fly in case the cron hasn't run for a new user
    compute_recommendations if allow_run && newish_user && suggested_tags.count.zero?

    # Return hash of tag string => number of readable notebooks
    suggested = suggested_tags.map(&:tag)
    # TODO: #360 - Fix when tag is normalized
    counts = Notebook
      .readable_by(self)
      .joins('LEFT OUTER JOIN tags ON tags.notebook_id = notebooks.id')
      .where('tags.tag IN (?)', suggested)
      .group(:tag)
      .count
    suggested
      .map {|tag| [tag, counts.fetch(tag, 0)]}
      .reject {|_tag, count| count.zero?}
      .sort_by {|_tag, count| -count + rand}
  end

  def self.create_with_omniauth(info, _provider)
    user = {
      email: info['email'],
      password: Devise.friendly_token[0, 20],
      confirmed_at: Time.now.utc.to_datetime.to_s,
      confirmation_token: nil,
      first_name: info.first_name,
      last_name: info.last_name
    }
    create!(user)
  end

  def active_for_authentication?
    if GalleryConfig.registration.require_admin_approval
      super && approved?
    else
      super
    end
  end

  def inactive_message
    if !approved? && GalleryConfig.registration.require_admin_approval
      :not_approved
    else
      super
    end
  end

  #########################################################
  # Internal helpers
  #########################################################

  private

  def apply_date_range(relation, min_date=nil, max_date=nil, field='updated_at')
    relation = relation.where("#{field} >= ?", min_date) if !min_date.blank?
    relation = relation.where("#{field} <= ?", max_date) if !max_date.blank?
    relation
  end
end
