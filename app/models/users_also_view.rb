# Model for users-also-viewed relationship
class UsersAlsoView < ApplicationRecord
  belongs_to :notebook
  belongs_to :other_notebook, class_name: 'Notebook'

  validates :notebook, :other_notebook, :score, presence: true

  # Nightly computation methods
  class << self
    def matrix_compute # rubocop: disable Metrics/AbcSize
      # List of unique [notebook id, user id] actions
      clicks = Click
        .where('updated_at > ?', 90.days.ago)
        .select(:notebook_id, :user_id)
        .distinct
        .map {|e| [e.notebook_id, e.user_id]}
      notebooks = clicks.map(&:first).uniq
      users = clicks.map(&:second).uniq
      num_notebooks = notebooks.count
      num_users = users.count

      # Map of notebook id => matrix row number, and the reverse
      notebook_id_map = notebooks.each_with_index.to_h
      reverse_notebook_id_map = notebooks.each_with_index.map {|k, v| [v, k]}.to_h
      # Map of user id => matrix column number
      user_id_map = users.each_with_index.to_h

      # Matrix of notebook-user actions
      unique_pairs = {}
      b = Matrix.zero(num_notebooks, num_users)
      clicks.each do |notebook_id, user_id|
        unique_pairs[notebook_id.to_s + " " + user_id.to_s] = 1
        b[notebook_id_map[notebook_id], user_id_map[user_id]] = 1
      end
      clicks = nil # rubocop: disable Lint/UselessAssignment

      # Notebook-notebook intersection matrix = number of users of both notebooks
      intersections = b * b.transpose
      b_density = unique_pairs.length.to_f / (num_notebooks * num_users)
      i_density = intersections.each_with_index
                .select {|value, row, column| value.nonzero?}
                .to_a.length
                .to_f / (intersections.row_count() * intersections.row_count())

      # Compute jaccard similarity row by row
      # Note: this could be faster with full matrix methods, but would also require
      # a fully dense matrix and therefore more memory.  Instead we use this array
      # holding the number of users of each notebook.  The size of the union of the
      # two sets of users is then sums[i] + sums[j] - intersections[i, j]
      sums = intersections.each(:diagonal).map{|value| value}
      UsersAlsoView.delete_all
      for i in 0..intersections.row_count() do
        row = intersections.row(i)
        notebook_id = reverse_notebook_id_map[i]
        top = row
          .to_a
          .each_with_index
          .select {|intersection, j| intersection.nonzero? && i != j}
          .map {|intersection, j| [intersection.to_f / (sums[i] + sums[j] - intersection), j]}
          .sort_by {|score, _j| -score}
          .take(25)
        records = top.map do |score, j|
          UsersAlsoView.new(
            notebook_id: notebook_id,
            other_notebook_id: reverse_notebook_id_map[j],
            score: score
          )
        end
        UsersAlsoView.import(records, validate: false)
      end
      "B=#{num_notebooks}x#{num_users} density=#{format('%.4f', b_density)}; I density=#{format('%.4f', i_density)}"
    end

    # Populate 'users also view' for initial notebook uploads
    def initial_upload(notebook, user)
      # When a notebook is uploaded, nobody has seen it but the author, so
      # populate users also view with the last few notebooks the author viewed
      other_notebooks = user
        .clicks
        .joins(:notebook)
        .where(action: 'viewed notebook')
        .where('clicks.created_at > ?', 180.days.ago)
        .where('notebooks.public = true')
        .where('notebooks.id != ?', notebook.id)
        .select('notebooks.id as nbid, MAX(clicks.created_at) as ts')
        .group('nbid')
        .order('ts DESC')
        .limit(10)
        .map(&:nbid)
      records = other_notebooks.map do |nbid|
        UsersAlsoView.new(
          notebook_id: notebook.id,
          other_notebook_id: nbid,
          score: 1.0
        )
      end
      UsersAlsoView.transaction do
        UsersAlsoView.where(notebook_id: notebook.id).delete_all # no callbacks
        UsersAlsoView.import(records, validate: false)
      end
    end
  end
end
