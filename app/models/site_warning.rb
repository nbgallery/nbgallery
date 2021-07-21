# Model for warning banner
class SiteWarning < ActiveRecord::Base
  belongs_to :user

  validates :level, :message, presence: true
end
