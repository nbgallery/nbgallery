# Model for user similarity scores
#
# We create a feature vector for each user based on the notebooks they've
# viewed and executed.  We then use cosine similarity to compute the
# similarity between each pair of users.
class UserSimilarity < ApplicationRecord
  belongs_to :user
  belongs_to :other_user, class_name: 'User'

  validates :user, :other_user, :score, presence: true

  # Cosine similarity score
  # Compute similarity for all user pairs simultaneously using sparse matrix
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

    # Sparse matrix of user-notebook scores - each row is a user feature vector
    r = Matrix.zero(num_users, num_notebooks)
    unique_pairs = {}
    clicks.each do |user_id, notebook_id, score|
      unique_pairs[notebook_id.to_s + " " + user_id.to_s] = 1
      r[user_id_map[user_id], notebook_id_map[notebook_id]] = score
    end
    clicks = nil # rubocop: disable Lint/UselessAssignment

    # User-user cosine similarity matrix
    rr = r * r.transpose
    d = Matrix.zero(rr.row_count)
    i=0
    rr.each(:diagonal) do | value |
      d[i, i] = value ** -0.5
      i += 1
    end
    similarity = d * rr * d
    r_density = unique_pairs.size.to_f / (num_users * num_notebooks)
    s_density = similarity.each_with_index
              .select {|value, row, column| value.nonzero?}
              .to_a.length
              .to_f / (similarity.row_count() * similarity.row_count())

    # Database top N similar users for each user
    UserSimilarity.delete_all
    for i in 0..similarity.row_count() do
      row = similarity.row(i)
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
    "R=#{num_users}x#{num_notebooks} density=#{format('%.4f', r_density)}; S density=#{format('%.4f', s_density)}"
  end
end
