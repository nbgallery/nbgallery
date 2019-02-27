# Summary of user clickstream actions
class UserSummary < ActiveRecord::Base
  belongs_to :user
  validates :user, presence: true

  def self.compute_percentiles(reputation)
    Ranker
      .rank(reputation.values, by: ->(values) {values[:user_rep_raw]})
      .each {|ranking| ranking.rankables.each {|r| r[:user_rep_pct] = ranking.percentile}}
    authors = reputation.select {|_user, r| r[:author_rep_raw] && r[:author_rep_raw] > 0.0}
    Ranker
      .rank(authors.values, by: ->(values) {values[:author_rep_raw]})
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
      batch_size: 500,
      validate: false,
      on_duplicate_key_update: %i[user_rep_raw user_rep_pct author_rep_raw author_rep_pct]
    )
  end

  def self.generate_all
    reputation = {}
    window = 1.year.ago
    User.find_each(batch_size: 100) do |user|
      # Basic metrics
      rep = reputation[user] = user.notebook_action_counts(min_date: window)

      # Reputation scores
      rep[:user_rep_raw] =
        rep[:view] +
        5 * rep[:feedbacks] +
        5 * rep[:comments] +
        10 * rep[:run] +
        20 * rep[:execute] +
        50 * rep[:functional_reviews]
      rep[:author_rep_raw] =
        rep[:users] +
        rep[:health_bonus] +
        10 * rep[:create_public] +
        5 * rep[:edit_other] +
        10 * rep[:langs] +
        10 * rep[:technical_reviews]
    end
    compute_percentiles(reputation)
    save(reputation)
  end
end
