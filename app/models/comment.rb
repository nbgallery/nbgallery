# Model for feedback
class Comment < ApplicationRecord 
    belongs_to :user
    belongs_to :notebook
end
  