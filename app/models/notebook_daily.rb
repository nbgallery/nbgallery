# Daily summary of notebook click actions
#
# Each day, we record the number of unique users ans executors of each notebook.
# We also compute a score reflecting the relative popularity of each notebook
# on this particular day.  These daily stats are are used for the activity
# sparkline and are the main component of the notebook trendiness score.
class NotebookDaily < ActiveRecord::Base
  belongs_to :notebook
  validates :notebook, presence: true

  def self.compute_all(days_ago=1)
    # maps of notebook_id => unique users, unique executors
    day = days_ago.days.ago.to_date
    users = user_set(Click, day)
    executors = user_set(ExecutionHistory, day)

    # merge executors into users
    executors.each do |nb, s|
      users[nb] ||= Set.new
      users[nb].merge(s)
    end
    max_count = users.map(&:second).map(&:count).max || 1.0
    log_max = Math.log(1.0 + max_count)

    # save to db
    records = users.map do |nb, s|
      NotebookDaily.new(
        notebook_id: nb,
        day: day,
        unique_users: s.count,
        unique_executors: executors[nb]&.count || 0,
        daily_score: Math.log(1.0 + s.count.to_f) / log_max
      )
    end
    NotebookDaily.transaction do
      NotebookDaily.where(day: day).delete_all # no callbacks
      NotebookDaily.import(records, validate: false, batch_size: 250)
    end
  end

  def self.age_off(days_ago=90)
    day = days_ago.days.ago.to_date
    NotebookDaily.where('day < ?', day).delete_all # no callbacks
  end

  def self.user_set(table, day)
    table
      .where('DATE(updated_at) = ?', day)
      .group(:notebook_id, :user_id)
      .map {|e| [e.notebook_id, e.user_id]}
      .group_by(&:first)
      .map {|nb, users| [nb, Set.new(users.map(&:second))]}
      .to_h
  end
end
