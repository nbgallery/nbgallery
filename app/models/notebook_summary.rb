# Summary of notebook clickstream actions
class NotebookSummary < ActiveRecord::Base
  belongs_to :notebook
  validates :notebook, presence: true

  def self.generate_all
    Notebook.find_each(&:update_summary)
  end
end
