# Notebook execution history
class ExecutionHistory < ApplicationRecord
  belongs_to :user
  belongs_to :notebook
end
