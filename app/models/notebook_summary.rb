# Summary of notebook clickstream actions
class NotebookSummary < ApplicationRecord
  belongs_to :notebook
  validates :notebook, presence: true

  def compute_completed_review(completed)
    date = completed.updated_at.strftime('%Y-%m-%d')
    latest_revision = notebook.revisions.order(id: :desc).first.id
    latest_is_reviewed = latest_revision && completed.revision_id == latest_revision

    self.review = completed.recent? ? 1.0 : 0.8
    self.review_description =
      if latest_revision && latest_is_reviewed
        "Current version reviewed on #{date}"
      elsif latest_revision
        "Previous version reviewed on #{date}"
      else
        "Reviewed on #{date}"
      end
  end

  def compute_reviews
    completed = notebook.reviews.where(status: 'completed').last
    if completed
      compute_completed_review(completed)
      return
    end

    if notebook.reviews.where(status: 'claimed').present?
      self.review = 0.6
      self.review_description = 'Review pending'
      return
    end

    queued = notebook.reviews.where(status: 'queued').last
    if queued
      self.review = queued.comment.starts_with?('Automatic') ? 0.4 : 0.2
      self.review_description = 'Nominated for review'
    else
      self.review = 0.0
      self.review_description = 'No reviews'
    end
  end

  def compute
    views = 0
    viewers = 0
    downloads = 0
    downloaders = 0
    runs = 0
    runners = 0
    notebook
      .clicks
      .where(action: ['viewed notebook', 'downloaded notebook', 'ran notebook'])
      .group(:user_id, :action)
      .count
      .map(&:flatten)
      .each do |_user_id, action, count|
        case action
        when 'viewed notebook'
          views += count
          viewers += 1
        when 'downloaded notebook'
          downloads += count
          downloaders += 1
        when 'ran notebook'
          runs += count
          runners += 1
        end
      end

    self.views = views
    self.unique_views = viewers
    self.downloads = downloads
    self.unique_downloads = downloaders
    self.runs = runs
    self.unique_runs = runners
    self.stars = notebook.stars.count
    health = notebook.health_status
    self.health = health[:adjusted_score]
    self.health_description = health[:description]
    self.trendiness = notebook.compute_trendiness
    compute_reviews

    if changed?
      save
      notebook.save # to reindex counts in solr
      true
    else
      false
    end
  end

  def self.compute_all
    # Trendiness and health only look at 30 days of activity, so once a
    # notebook is "idle" for that long, the summary will not change.
    idle_days = 32
    recompute = Set.new(
      Click
        .where('updated_at >= ?', idle_days.days.ago)
        .select(:notebook_id)
        .distinct
        .map(&:notebook_id)
    )
    recompute.merge(
      Execution
        .joins(:code_cell)
        .where('executions.updated_at >= ?', idle_days.days.ago)
        .select(:notebook_id)
        .distinct
        .map(&:notebook_id)
    )
    recompute.merge(
      Review
        .where('updated_at >= ?', idle_days.days.ago)
        .select(:notebook_id)
        .distinct
        .map(&:notebook_id)
    )

    recompute.each_slice(100) do |slice|
      Notebook.where(id: slice).find_each do |nb|
        nb.notebook_summary.compute
      end
    end
  end
end
