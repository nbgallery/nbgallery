# Model for user similarity scores
class UserSimilarity < ActiveRecord::Base
  belongs_to :user
  belongs_to :other_user, class_name: 'User'

  validates :user, :other_user, :score, presence: true

  # Cosine similarity score
  def self.vector_similarity(vi, vj)
    return 0.0 if vi.empty? or vj.empty?
    m1 = Math.sqrt(vi.map {|_id, x| x * x}.reduce(0, :+))
    m2 = Math.sqrt(vj.map {|_id, x| x * x}.reduce(0, :+))
    dot = vi.map {|id, x| x * vj.fetch(id, 0.0)}.reduce(:+)
    dot / (m1 * m2)
  end

  def self.compute(which=nil)
    max_per_user = 50

    # Get feature vectors for all users
    vectors = {}
    User.includes(:stars, :clicks).find_each do |user|
      vectors[user.id] = user.feature_vector
    end

    # Compute similarity; keep top N for each user
    vectors.each do |i, vi|
      next if which && which != i
      scores = []
      vectors.each do |j, vj|
        next if i == j
        score = vector_similarity(vi, vj)
        next if score < 0.2 # don't bother with low scores
        scores.push([j, score])
      end
      scores = scores.sort_by {|_j, score| -score}.take(max_per_user)
      records = scores.map do |j, score|
        UserSimilarity.new(
          user_id: i,
          other_user_id: j,
          score: score
        )
      end
      UserSimilarity.transaction do
        UserSimilarity.where(user_id: i).delete_all # no callbacks
        UserSimilarity.import(records, validate: false)
      end
    end
  end
end
