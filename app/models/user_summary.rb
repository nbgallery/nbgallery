# Summary of user clickstream actions
class UserSummary < ActiveRecord::Base
  belongs_to :user
  validates :user, presence: true

  def self.health_bonus(notebook_ids)
    return 0 if notebook_ids.blank?
    NotebookSummary
      .where(notebook_id: notebook_ids)
      .pluck(:health)
      .select {|h| Notebook.health_symbol(h) == :healthy}
      .map {|h| 10.0 * h}
      .reduce(0, :+)
  end

  def self.compute_percentiles(reputation)
    Ranker
      .rank(reputation.values, by: ->(values) {values[:user_rep_raw]})
      .each {|ranking| ranking.rankables.each {|r| r[:user_rep_pct] = ranking.percentile}}
    Ranker
      .rank(reputation.values, by: ->(values) {values[:author_rep_raw]})
      .each {|ranking| ranking.rankables.each {|r| r[:author_rep_pct] = ranking.percentile}}
    reputation
  end

  def self.save(reputation)
    summaries = reputation.map do |user, data|
      UserSummary.new(
        user_id: user.id,
        user_rep_raw: data[:user_rep_raw],
        user_rep_pct: data[:user_rep_pct],
        author_rep_raw: data[:author_rep_raw],
        author_rep_pct: data[:author_rep_pct]
      )
    end
    UserSummary.import(
      summaries,
      batch_size: 1000,
      validate: false,
      on_duplicate_key_update: %i[user_rep_raw user_rep_pct author_rep_raw author_rep_pct]
    )
  end

  def self.generate_all
    reputation = {}
    window = 1.year.ago
    User
      .includes(clicks: { notebook: :creator }, executions: [:notebook])
      .find_each(batch_size: 100) do |user|
        # Basic metrics
        recent_clicks = user.clicks.select {|c| c.updated_at >= window}
        recent_execs = user.executions.select {|e| e.updated_at >= window}
        created = user
          .clicks
          .select {|c| c.action == 'created notebook' && c.notebook.public && c.notebook.creator == user}
          .map(&:notebook_id)
        rep = reputation[user] = user.notebook_action_counts(
          actions: recent_clicks,
          created: created,
          executions: recent_execs
        )
        rep[:health_bonus] = UserSummary.health_bonus(created)

        # Reputation scores
        rep[:user_rep_raw] =
          rep[:view] +
          10 * rep[:run] +
          20 * rep[:execute]
        rep[:author_rep_raw] =
          rep[:users] +
          rep[:health_bonus] +
          10 * rep[:create_public] +
          5 * rep[:edit_other] +
          10 * rep[:langs]
      end
    compute_percentiles(reputation)
    save(reputation)
  end
end
