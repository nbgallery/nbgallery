require 'test_helper'

# :nodoc:
class AdminControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should get health' do
    get :health
    assert_response :success
  end

  test 'should get recommender_summary' do
    get :recommender_summary
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
