# Summary of user clickstream actions
class UserSummary < ActiveRecord::Base
  belongs_to :user
  validates :user, presence: true

  def self.health_bonus(notebook_ids)
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

  def self.generate_all
    reputation = {}
    window = 1.year.ago
    User
      .includes(clicks: { notebook: :creator }, executions: [:notebook])
      .find_each(batch_size: 100) do |user|
        # Basic metrics
        rep = reputation[user] = user.notebook_action_counts(window)
        created = user.notebooks_created.where(public: true).pluck(:id)
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
          50 * rep[:langs]
      end
    compute_percentiles(reputation)

    # Save
    User.find_each do |user|
      summary = user.user_summary
      summary.user_rep_raw = reputation[summary.user][:user_rep_raw]
      summary.user_rep_pct = reputation[summary.user][:user_rep_pct]
      summary.author_rep_raw = reputation[summary.user][:author_rep_raw]
      summary.author_rep_pct = reputation[summary.user][:author_rep_pct]
      summary.save
    end
  end
end
