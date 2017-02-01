# Code cell model
class CodeCell < ActiveRecord::Base
  belongs_to :notebook
  has_many :executions, dependent: :destroy

  validates :md5, :ssdeep, :notebook, :cell_number, presence: true
end
