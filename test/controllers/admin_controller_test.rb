require 'test_helper'

# :nodoc:
class AdminControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should get internal' do
    get :internal
    assert_response :success
  end

  test 'should get users' do
    get :users
    assert_response :success
  end

  test 'should get user' do
    get :user
    assert_response :success
  end

  test 'should get suggestions' do
    get :suggestions
    assert_response :success
  end

  test 'should get user_similarity' do
    get :user_similarity
    assert_response :success
  end

  test 'should get notebook_similarity' do
    get :notebook_similarity
    assert_response :success
  end
end
