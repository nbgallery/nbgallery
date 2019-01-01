# RecommendedReviewer model
class RecommendedReviewer < ActiveRecord::Base
  belongs_to :user
  belongs_to :review
end
