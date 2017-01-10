# Model for user similarity scores
class UserSimilarity < ActiveRecord::Base
  belongs_to :user
  belongs_to :other_user, class_name: 'User'

  validates :user, :other_user, :score, presence: true

  def self.vector_similarity(vi, vj)
    return 0.0 if vi.empty? or vj.empty?
    m1 = Math.sqrt(vi.map {|_id, x| x * x}.reduce(0, :+))
    m2 = Math.sqrt(vj.map {|_id, x| x * x}.reduce(0, :+))
    dot = vi.map {|id, x| x * vj.fetch(id, 0.0)}.reduce(:+)
    dot / (m1 * m2)
  end

  def self.compute_all
    # This is quadratic in number of users.
    # We may need to rebalance holding stuff in memory vs db queries.
    vectors = {}
    User.includes(:stars, :clicks).find_each do |user|
      vectors[user.id] = user.feature_vector
    end
    vectors.each do |i, vi|
      to_insert = []
      vectors.each do |j, vj|
        next if i >= j
        score = vector_similarity(vi, vj)
        next if score < 0.2 # don't bother storing low scores
        to_insert << UserSimilarity.new(
          user_id: i,
          other_user_id: j,
          score: score
        )
        to_insert << UserSimilarity.new(
          user_id: j,
          other_user_id: i,
          score: score
        )
      end
      UserSimilarity.import(
        to_insert,
        on_duplicate_key_update: [:score],
        validate: false,
        batch_size: 1000
      )
    end
  end
end
