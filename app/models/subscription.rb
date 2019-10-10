# Subscriptions model
class Subscription < ActiveRecord::Base
  belongs_to :sub, polymorphic: true
  #belongs_to :user, polymorphic: true
  #belongs_to :notebook, polymorphic: true
  #belongs_to :group, polymorphic: true
  #belongs_to :tag, polymorphic: true

  validates :sub_id, format: { with: /\A[0-9-]+\z/, message: 'must be only be numbers' }
  validates :sub_type, format: { with: /\A[a-z-]+\z/, message: 'must be only be lowercase letters' }
  validates :sub_id, :sub_type, presence: true

  include ExtendableModel

end
