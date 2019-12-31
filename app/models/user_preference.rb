class UserPreference < ActiveRecord::Base
  belongs_to :user
  
  include ExtendableModel

end
