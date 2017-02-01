# Code cell model
class CodeCell < ActiveRecord::Base
  belongs_to :notebook
  has_many :executions, dependent: :destroy
end
