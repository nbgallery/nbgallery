# Model for notebook similarity scores
#
# Currently we use Opensearch's "more like this" (MLT) search, which uses TF-IDF to
# identify similar notebooks.  The MLT query is quick enough to perform on the
# fly on the notebook view page.  However, the similar-notebooks recommender
# ends up doing the same MLT query repeatedly for more popular notebooks, so
# it improves recommender performance to cache the MLT results in the notebook
# similarity table in the database.
class NotebookSimilarity < ApplicationRecord
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
      pct = recomputed.to_f / Notebook.count
      "recomputed #{recomputed}/#{Notebook.count} (#{format('%.3f', pct)})"
    end

    def compute_for(notebook)
      per_notebook = 25
      results = Notebook.search(
        body: {
          query: {
            more_like_this: {
              fields: [:title, :description, :tags],
              like: [
                {
                  _index: Notebook.search_index.name,
                  _id: notebook.id
                }
              ],
              min_term_freq: 1,
              min_doc_freq: 1
            }
          }
        },
        page: 1,
        per_page: per_notebook
      )
      records = results.each_with_index.map do |nb, i|
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
