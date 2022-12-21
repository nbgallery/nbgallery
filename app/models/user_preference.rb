class UserPreference < ApplicationRecord
  belongs_to :user
  
  include ExtendableModel

end
