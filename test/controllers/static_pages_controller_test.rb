require 'test_helper'

# :nodoc:
class StaticPagesControllerTest < ActionController::TestCase
  test 'should get home' do
    get :home
    assert_response :success
  end

  test 'should get help' do
    get :help
    assert_response :success
  end

  test 'should get feed' do
    get :feed
    assert_response :success
  end

  test 'should get admin' do
    get :admin
    assert_response :success
  end
end
