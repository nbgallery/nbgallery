# Model for feedback
class Feedback < ApplicationRecord 
  belongs_to :user
  belongs_to :notebook
end
