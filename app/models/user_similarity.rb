# Model for user similarity scores
#
# We create a feature vector for each user based on the notebooks they've
# viewed and executed.  We then use cosine similarity to compute the
# similarity between each pair of users.
class UserSimilarity < ActiveRecord::Base
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
    r = NMatrix.new([num_users, num_notebooks], stype: :yale, dtype: :float32)
    clicks.each do |user_id, notebook_id, score|
      r[user_id_map[user_id], notebook_id_map[notebook_id]] = score
    end
    clicks = nil # rubocop: disable Lint/UselessAssignment

    # User-user cosine similarity matrix
    rr = r.dot(r.transpose)
    d = NMatrix.diagonal(rr.diagonal.map {|x| x**-0.5}, stype: :yale, dtype: :float32)
    similarity = d.dot(rr).dot(d)
    r.extend(NMatrix::YaleFunctions)
    similarity.extend(NMatrix::YaleFunctions)
    r_density = r.yale_size.to_f / r.size
    s_density = similarity.yale_size.to_f / similarity.size

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
    "R=#{num_users}x#{num_notebooks} density=#{format('%.4f', r_density)}; S density=#{format('%.4f', s_density)}"
  end
end
