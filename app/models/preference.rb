# Model for user preferences
class Preference < ActiveRecord::Base
  belongs_to :user
end
