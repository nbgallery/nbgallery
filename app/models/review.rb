# Notebook review model
class Review < ApplicationRecord
  belongs_to :reviewer, class_name: 'User', inverse_of: 'reviews', optional: true
  belongs_to :notebook
  belongs_to :revision
  has_many :recommended_reviewers, dependent: :destroy

  include ExtendableModel
  def self.custom_simplify_email?(_review, _message)
    false
  end

  def simplify_email?(message)
    Review.custom_simplify_email?(self, message)
  end

  # Is user allowed to claim this review?
  def reviewable_by(user)
    # Cannot review your own notebook
    return false if notebook.creator_id == user.id && !user.admin?

    # Type-specific logic that can be overridden by extensions
    case revtype
    when 'technical'
      Review.technical_review_allowed?(self, user)
    when 'functional'
      Review.functional_review_allowed?(self, user)
    when 'compliance'
      Review.compliance_review_allowed?(self, user)
    else
      # unsupported revision type - should never get here
      false
    end
  end

  # Is user recommended as a reviewer?
  def recommended_reviewer?(user)
    recommended_reviewers.where(user: user).present?
  end

  # Is this review "recent"?
  def recent?
    latest_revision_id = notebook.revisions.order(id: :desc).first.id
    if latest_revision_id
      # Revision tracking is on, so let's say this review is recent if it's for
      # the current revision and is less than a year old.
      revision_id == latest_revision_id && updated_at > 1.year.ago
    else
      # Revision tracking is off, so let's take a stricter definition of recent.
      updated_at > 6.months.ago
    end
  end

  # Business logic for whether users are allowed to perform different types
  # of reviews.  These are designed to be optionally replaced with custom logic
  # implemented in an extension.
  class << self
    # Is user allowed to perform a technical review?
    # We want users with experience *writing* notebooks and therefore
    # (hopefully) mindful of best practices from a coding perspective.
    def technical_review_allowed?(review, user)
      return true if user.admin?
      (user.author_rep_pct || 0.0) >= 50.0 || review.recommended_reviewer?(user)
    end

    # Is user allowed to perform a functional review?
    # We want users with experience *running* notebooks and who will have a
    # good idea whether this notebook does what it's supposed to.  There may
    # be enterprise-specific requirements here (e.g. you want someone from the
    # same team to review).
    def functional_review_allowed?(review, user)
      return true if user.admin?

      has_run_notebook = Click
        .where(notebook: review.notebook)
        .where(user: user)
        .where(action: ['ran notebook', 'executed notebook'])
        .present?
      return false unless has_run_notebook
      (user.user_rep_pct || 0.0) >= 75.0 || review.recommended_reviewer?(user)
    end

    # Is user allowed to perform a compliance review?
    # This is probably enterprise-specific; e.g. only members of the corporate
    # compliance/policy team can do this kind of review.  So, just default to
    # admins here and assume an extension will install specific business logic.
    def compliance_review_allowed?(_review, user)
      user.admin?
    end
  end

  # Queue recommender
  # Identifies high-value notebooks as candidates for review
  class << self
    def relevant_clicks(days)
      Click
        .where(action: ['ran notebook', 'executed notebook', 'downloaded notebook'])
        .where('updated_at > ?', days.days.ago)
    end

    # The most-used notebooks are obviously important
    def most_used_notebooks(days, topn)
      relevant_clicks(days)
        .select('notebook_id, count(*) as c')
        .group(:notebook_id)
        .order('c desc')
        .limit(topn)
        .map {|e| [e.notebook_id, e.c]}
    end

    # We'll call users who only use a few notebooks "focused" users.
    # The notebooks they use most are presumably valuable.
    def focused_user_notebooks(days, topn)
      # Identify focused users
      focused_users = relevant_clicks(days)
        .select('user_id, count(distinct(notebook_id)) as c')
        .group(:user_id)
        .having('c <= 5')
        .map(&:user_id)

      # Most used notebooks by the set of focused users
      relevant_clicks(days)
        .where(user_id: focused_users)
        .select('notebook_id, count(*) as c')
        .group(:notebook_id)
        .order('c desc')
        .limit(topn)
        .map {|e| [e.notebook_id, e.c]}
    end

    # Notebooks that are used repeatedly by the same users are important.
    def repeat_user_notebooks(days, topn, repeat_count)
      # Compute (notebook, user, # unique days used)
      # Keep only tuples where user has used notebook many times.
      user_notebook_counts = relevant_clicks(days)
        .select('notebook_id, user_id, count(distinct(date(updated_at))) as c')
        .group(:notebook_id, :user_id)
        .having('c >= ?', repeat_count)
        .map {|e| [e.notebook_id, e.user_id, e.c]}

      # Now keep the notebooks with the most repeat users.
      user_notebook_counts
        .group_by(&:first)
        .map {|notebook_id, entries| [notebook_id, entries.count, entries.map(&:last).sum]}
        .sort {|a, b| [b.second, b.third] <=> [a.second, a.third]}
        .take(topn)
    end

    # Determine notebooks that should probably be reviewed based on usage.
    def top_notebooks(days, topn)
      # Get the top notebooks by each of these different metrics.
      most_used = most_used_notebooks(days, topn * 2)
      focused = focused_user_notebooks(days, topn * 2)
      repeats = repeat_user_notebooks(days, topn * 2, days / 10)

      # Keep the ones that appear in the most (ideally all) of those lists.
      # Use position in the lists as tiebreaker (the i/1000 part below).
      scores = Hash.new(0.0)
      [focused, most_used, repeats].each do |ids|
        ids.map(&:first).reverse.each_with_index {|id, i| scores[id] += 1.0 + i / 1000.0}
      end

      # Generate comments to explain the ranking
      comments = Hash.new {|h, k| h[k] = []}
      most_used.each_with_index do |a, i|
        id, uses = a
        comments[id].append("#{uses} uses (##{i + 1})")
      end
      focused.each_with_index do |a, i|
        id, uses = a
        comments[id].append("#{uses} uses by focused users (##{i + 1})")
      end
      repeats.each_with_index do |a, i|
        id, users, uses = a
        comments[id].append("#{users} repeat users with #{uses} uses (##{i + 1})")
      end

      # Return [notebook id, comments], sorted by score
      scores.sort_by {|_id, score| -score}.map {|id, _score| [id, comments[id]]}.take(topn)
    end

    # Determine if notebook is already queued or recently reviewed
    def needs_review(notebook_id, revtype, comments)
      latest_revision = Notebook.find(notebook_id).revisions.last
      latest_review = Review.where(revtype: revtype, notebook_id: notebook_id).last

      # If no existing review, obviously it goes into the queue
      return true unless latest_review

      # Don't add if it's already in the queue, but update revision and comments
      if latest_review.status == 'queued'
        if latest_review.revision != latest_revision
          latest_review.comments = comments
          latest_review.revision = latest_revision
          latest_review.save
        end
        return false
      end

      # At this point, we have a claimed or completed review.  But is it recent?
      # If the last review isn't recent, we want a new one.
      !latest_review.recent?
    end

    # Remove from queue if usage has dropped off
    def prune_queue(top_nbs)
      # Remove anything that's still 'queued' but not in the top nbs list
      Review
        .where(status: 'queued')
        .where.not(notebook_id: top_nbs)
        .destroy_all
    end

    # Add top notebooks into the review queue
    def generate_queue(topn=nil)
      return unless GalleryConfig.reviews.any? {|_revtype, options| options.enabled}

      # Queue for review up to 50 or 5% of notebooks (whichever is smaller)
      topn ||= [50, Notebook.where(public: true).count / 20 + 1].min
      days = 90
      # Add new queue entries
      to_add = []
      top_nbs = top_notebooks(days, topn)
      top_nbs.each_with_index do |a, i|
        id, comments = a
        comment_text = "Automatically nominated based on usage (##{i + 1}): " + comments.join('; ')
        GalleryConfig.reviews.each do |revtype, options|
          next unless options.enabled
          next unless needs_review(id, revtype, comment_text)
          to_add.append(
            Review.new(
              notebook_id: id,
              revision: Notebook.find(id).revisions.last,
              revtype: revtype,
              status: 'queued',
              comments: comment_text
            )
          )
        end
      end
      Review.import(to_add, validate: false)

      # Remove old entries
      prune_queue(top_nbs.map(&:first))
      nil
    end
  end
end
