# Model for notebook similarity scores
class NotebookSimilarity < ActiveRecord::Base
  belongs_to :notebook
  belongs_to :other_notebook, class_name: 'Notebook'

  validates :notebook, :other_notebook, :score, presence: true

  # Nightly computation methods
  class << self
    # Compute notebook similarities
    def compute_all
      day_of_week = Time.current.wday
      old_threshold = 30.days.ago
      recomputed = 0
      Notebook.find_each(batch_size: 100) do |nb|
        recompute =
          nb.content_updated_at > old_threshold ||
          nb.id % 7 == day_of_week ||
          nb.notebook_similarities.empty?
        next unless recompute
        compute_for(nb)
        recomputed += 1
      end
      recomputed
    end

    def compute_for(notebook)
      per_notebook = 25
      sunspot = Sunspot.more_like_this(notebook) do
        paginate page: 1, per_page: per_notebook
      end
      records = sunspot.results.each_with_index.map do |nb, i|
        # Solr's MLT doesn't have a score, so go from 1.0 down to 0.5
        NotebookSimilarity.new(
          notebook_id: notebook.id,
          other_notebook_id: nb.id,
          score: 1.0 - i * (0.5 / per_notebook)
        )
      end
      NotebookSimilarity.transaction do
        NotebookSimilarity.where(notebook_id: notebook.id).delete_all # no callbacks
        NotebookSimilarity.import(records, validate: false)
      end
    end
  end
end
