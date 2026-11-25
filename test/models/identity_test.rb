require 'test_helper'

class IdentityTest < ActiveSupport::TestCase
  def user_info
    @user_info ||= OmniAuth::AuthHash.new(
      name: 'Mr X',
      first_name: 'Mr',
      last_name: 'X',
      email: 'mr.x@example.com',
      nickname: 'mr.x@example.com'
    )
  end

  def omniauth_hash
    @omniauth_hash ||= OmniAuth::AuthHash.new(
      provider: %w[azure_activedirectory_v2 facebook github gitlab google_oauth2 twitter].sample,
      uid: 'e3b8c0b1-68de-454e-8cdb-d7e2d8e9390a',
      info: user_info
    )
  end

  def ensure_user_does_not_exist
    User.destroy_by(email: user_info.email) # if it exists
  end

  def create_user
    User.create!(
      password: 'Password #123456',
      **user_info.slice(:email, :first_name, :last_name)
    )
  end

  setup do
    ensure_user_does_not_exist
  end

  test 'it creates new users' do
    identity = assert_difference -> {User.count + Identity.count}, 2 do
      Identity.create_with_omniauth(omniauth_hash)
    end

    assert_equal omniauth_hash.uid, identity.uid

    user = identity.user
    assert_equal user_info.email, user.email
    assert_equal user_info.first_name, user.first_name
    assert_equal user_info.last_name, user.last_name
  end

  test 'it associates existing users with new SSO identities' do
    user = create_user
    identity = assert_difference -> {Identity.count} do
      Identity.create_with_omniauth(omniauth_hash)
    end

    assert_equal user.id, identity.user_id
  end
end
