# Model for warning banner
class Warning < ActiveRecord::Base
  belongs_to :user

  validates :level, :message, presence: true
end
