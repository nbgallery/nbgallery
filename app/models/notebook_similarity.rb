# Model for notebook similarity scores
class NotebookSimilarity < ActiveRecord::Base
  belongs_to :notebook
  belongs_to :other_notebook, class_name: 'Notebook' # rubocop: disable Rails/InverseOf

  validates :notebook, :other_notebook, :score, presence: true

  # Nightly computation methods
  class << self
    # Compute notebook similarities
    def compute_all
      NotebookSimilarity.delete_all # not used, for now
    end
  end
end
