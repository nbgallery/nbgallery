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
      Notebook.find_each do |nb|
        ids.push(nb.id)
        nb_clicks = nb.clicks.where('updated_at > ?', 90.days.ago).pluck(:user_id)
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
  end
end
