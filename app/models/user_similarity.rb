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
    User.includes(:stars).find_each(batch_size: 100) do |user|
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

  def self.matrix_compute # rubocop: disable Metrics/AbcSize
    # List of unique [user id, notebook id, score] actions where score is 1.0
    # if user has executed notebook or 0.5 otherwise (e.g. only viewed)
    clicks = Click
      .where('updated_at > ?', 90.days.ago)
      .select("user_id, notebook_id, MAX(IF(action='executed_notebook',1.0,0.5)) AS score")
      .group('user_id, notebook_id')
      .map {|e| [e.user_id, e.notebook_id, e.score.to_f]}
    users = clicks.map(&:first).uniq
    notebooks = clicks.map(&:second).uniq
    num_users = users.count
    num_notebooks = notebooks.count

    # Map of user id => matrix row number, and the reverse
    user_id_map = users.each_with_index.to_h
    reverse_user_id_map = users.each_with_index.map {|k, v| [v, k]}.to_h
    # Map of notebook id => matrix column number
    notebook_id_map = notebooks.each_with_index.to_h

    # Sparse matrix of user-notebook scores
    r = NMatrix.new([num_users, num_notebooks], stype: :yale, dtype: :float32)
    clicks.each do |user_id, notebook_id, score|
      r[user_id_map[user_id], notebook_id_map[notebook_id]] = score
    end
    clicks = nil # rubocop: disable Lint/UselessAssignment

    # User-user cosine similarity matrix
    rr = r.dot(r.transpose)
    d = NMatrix.diagonal(rr.diagonal.map {|x| x**-0.5}, stype: :yale, dtype: :float32)
    similarity = d.dot(rr).dot(d)

    # Database top N similar users for each user
    UserSimilarity.delete_all
    similarity.each_row.each_with_index do |row, i|
      user_id = reverse_user_id_map[i]
      top = row
        .to_a
        .each_with_index
        .reject {|_score, j| i == j}
        .sort_by {|score, _j| -score}
        .take(25)
      records = top.map do |score, j|
        UserSimilarity.new(
          user_id: user_id,
          other_user_id: reverse_user_id_map[j],
          score: score
        )
      end
      UserSimilarity.import(records, validate: false)
    end
    nil
  end
end
