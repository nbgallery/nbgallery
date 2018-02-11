# Notebook execution history
class ExecutionHistory < ActiveRecord::Base
  belongs_to :user
  belongs_to :notebook
end
