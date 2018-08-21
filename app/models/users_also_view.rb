# Model for users-also-viewed relationship
class UsersAlsoView < ActiveRecord::Base
  belongs_to :notebook
  belongs_to :other_notebook, class_name: 'Notebook'

  validates :notebook, :other_notebook, :score, presence: true

  # Nightly computation methods
  class << self
    # Compute score to reflect user view overlap
    def compute(which=nil)
      max_per_notebook = 50

      # Compute set of users viewing each notebook
      clicks = {}
      ids = []
      Notebook.find_each(batch_size: 100) do |nb|
        ids.push(nb.id)
        nb_clicks = nb.clicks.where('updated_at > ?', 90.days.ago).select(:user_id).distinct.pluck(:user_id)
        clicks[nb.id] = Set.new(nb_clicks)
      end

      # Compute overlap score using Jaccard index
      ids.each do |i|
        next if which && which != i
        scores = []
        ids.each do |j|
          next if i == j
          intersection = clicks[i].intersection(clicks[j]).count
          union = clicks[i].union(clicks[j]).count
          jaccard = union.nonzero? ? intersection.to_f / union : 0.0
          scores.push([j, jaccard])
        end
        scores = scores.sort_by {|_j, jaccard| -jaccard}.take(max_per_notebook)
        records = scores.map do |j, jaccard|
          UsersAlsoView.new(
            notebook_id: i,
            other_notebook_id: j,
            score: jaccard
          )
        end
        UsersAlsoView.transaction do
          UsersAlsoView.where(notebook_id: i).delete_all # no callbacks
          UsersAlsoView.import(records, validate: false)
        end
      end
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
        .where('notebooks.public = TRUE')
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
