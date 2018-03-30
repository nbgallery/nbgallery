# Model for clickstream actions (viewed notebook, etc)
class Click < ActiveRecord::Base
  belongs_to :user
  belongs_to :notebook

  validates :user, :action, presence: true

  def self.feed(user, use_admin=false)
    # Preload associated notebooks and users
    clicks = Click.includes(:notebook, :user)
    # Also need to explicitly join to make the rest work
    clicks = clicks
      .joins('JOIN notebooks ON notebooks.id = clicks.notebook_id')
      .joins('LEFT OUTER JOIN tags ON notebooks.id = tags.notebook_id')
    # Now pull the click events we want
    # Multiple edit events within a single day are compressed into one entry
    columns = [
      'clicks.id',
      'clicks.user_id',
      'clicks.action',
      'clicks.notebook_id',
      'MAX(clicks.updated_at) AS updated_at',
      'DATE(clicks.updated_at) AS day',
      "GROUP_CONCAT(DISTINCT tags.tag SEPARATOR ' ') AS tags"
    ]
    Notebook
      .readable_join(clicks, user, use_admin)
      .select(columns.join(', '))
      .where(
        "action IN (?) OR (action = 'shared notebook' AND tracking = ?)",
        ['created notebook', 'edited notebook', 'made notebook public'],
        user.id
      )
      .where('clicks.updated_at > ?', 90.days.ago)
      .group(:user_id, :action, :notebook_id, :day)
      .order('updated_at DESC')
  end
end
