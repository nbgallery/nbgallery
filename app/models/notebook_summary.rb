# Summary of notebook clickstream actions
class NotebookSummary < ActiveRecord::Base
  belongs_to :notebook
  validates :notebook, presence: true

  def self.generate_all
    view_weights = (0..30).map {|i| 1.0 - Math.exp(i / 6.0) / Math.exp(5.0)}
    creation_weights = (0..180).map {|i| 1.0 - Math.exp(i / 60.0) / (2.0 * Math.exp(30.0))}

    # Compute trendiness score
    trendiness = {}
    max_trendiness = 0.0
    Notebook.find_each do |nb|
      # Start with unique viewers, decaying to 0 over 30 days
      trendy = nb.clicks
        .where('updated_at > ?', 30.days.ago)
        .select('count(distinct user_id) as users, datediff(now(), updated_at) as age')
        .group('age')
        .map {|result| result.users * (view_weights[result.age] || 0.0)}
        .reduce(&:+)
      trendy ||= 0.0

      # Factor in age of notebook, decaying to 0.5 over 180 days
      created_age = ((Time.current - nb.created_at) / 24.hours).to_i
      trendy *= (creation_weights[created_age] || 0.5)

      # Track the max for scaling later
      max_trendiness = [max_trendiness, trendy].max
      trendiness[nb.id] = trendy
    end

    # Update all other metrics
    Notebook.find_each do |nb|
      trendy = (max_trendiness > 0.0 ? trendiness[nb.id] / max_trendiness : 0.0)
      nb.update_summary(trendy)
    end
  end
end
