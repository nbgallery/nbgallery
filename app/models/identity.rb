class Identity < ActiveRecord::Base
  belongs_to :user

  def self.find_with_omniauth(auth)
    find_by(uid: auth['uid'], provider: auth['provider'])
  end

  def self.create_with_omniauth(auth)
    puts "Creating user from"
    puts auth
    user = User.create_with_omniauth(auth.info, auth.provider)
    puts user.inspect
    create(uid: auth['uid'], provider: auth['provider'], user_id: user.id)
  end
end
