# Notebook review model
class Review < ActiveRecord::Base
  belongs_to :reviewer, class_name: 'User', inverse_of: 'reviews'
  belongs_to :notebook
  belongs_to :revision
  has_many :recommended_reviewers, dependent: :destroy

  include ExtendableModel

  # Is user allowed to claim this review?
  def reviewable_by(user)
    # TODO: make extension-friendly
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

  # Business logic for whether users are allowed to perform different types
  # of reviews.  These are designed to be optionally replaced with custom logic
  # implemented in an extension.
  class << self
    # Is user allowed to perform a technical review?
    # We want users with experience *writing* notebooks and therefore
    # (hopefully) mindful of best practices from a coding perspective.
    def technical_review_allowed?(review, user)
      return true if user.admin?
      user.author_rep_pct >= 50.0 || review.recommended_reviewer?(user)
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
      user.user_rep_pct >= 75.0 || review.recommended_reviewer?(user)
    end

    # Is user allowed to perform a compliance review?
    # This is probably enterprise-specific; e.g. only members of the corporate
    # compliance/policy team can do this kind of review.  So, just default to
    # admins here and assume an extension will install specific business logic.
    def compliance_review_allowed?(_review, user)
      user.admin?
    end
  end
end
