# Summary of notebook clickstream actions
class NotebookSummary < ActiveRecord::Base
  belongs_to :notebook
  validates :notebook, presence: true

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

    if changed?
      save
      notebook.save # to reindex counts in solr
      true
    else
      false
    end
  end

  def self.compute_all
    Notebook.find_each(batch_size: 100) do |nb|
      nb.notebook_summary.compute
    end
  end
end
