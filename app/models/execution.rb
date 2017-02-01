# Code cell execution model
class Execution < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_cell
  has_one :notebook, through: :code_cell

  validates :success, not_nil: true
  validates :runtime, :user, :code_cell, presence: true
end
