# Model for warning banner
class SiteWarning < ApplicationRecord
  belongs_to :user

  validates :level, :message, presence: true
end
