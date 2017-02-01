# Code cell execution model
class Execution < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_cell
  has_one :notebook, through: :code_cell
end
