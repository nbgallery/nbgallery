# Code cell model
class CodeCell < ActiveRecord::Base
  belongs_to :notebook
  has_many :executions, dependent: :destroy

  validates :md5, :ssdeep, :notebook, :cell_number, presence: true

  # Return code associated with this cell
  # Note: this is not particularly efficient
  def source
    notebook.notebook.code_cells_source[cell_number]
  end
end
