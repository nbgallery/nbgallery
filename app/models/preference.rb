# Model for user preferences
class Preference < ApplicationRecord
  belongs_to :user
end
