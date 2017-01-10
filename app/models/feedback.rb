# Model for feedback
class Feedback < ActiveRecord::Base
  belongs_to :user
  belongs_to :notebook
end
