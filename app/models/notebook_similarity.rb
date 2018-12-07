# Model for notebook similarity scores
#
# Currently we use Solr's "more like this" (MLT) search, which uses TF-IDF to
# identify similar notebooks.  The MLT query is quick enough to perform on the
# fly on the notebook view page.  However, the similar-notebooks recommender
# ends up doing the same MLT query repeatedly for more popular notebooks, so
# it improves recommender performance to cache the MLT results in the notebook
# similarity table in the database.
#
# More info on MLT:
# https://lucene.apache.org/solr/guide/6_6/morelikethis.html
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
      pct = recomputed.to_f / Notebook.count
      "recomputed #{recomputed}/#{Notebook.count} (#{format('%.3f', pct)})"
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
