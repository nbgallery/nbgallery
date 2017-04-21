# User identity model
class Identity < ActiveRecord::Base
  belongs_to :user

  def self.find_with_omniauth(auth)
    find_by(uid: auth['uid'], provider: auth['provider'])
  end

  def self.create_with_omniauth(auth)
    Rails.logger.debug('Creating user from')
    Rails.logger.debug(auth)
    user = User.create_with_omniauth(auth.info, auth.provider)
    Rails.logger.debug(user.inspect)
    create(uid: auth['uid'], provider: auth['provider'], user_id: user.id)
  end
end
