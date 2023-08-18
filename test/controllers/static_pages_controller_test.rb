require 'test_helper'

# :nodoc:
class StaticPagesControllerTest < ActionController::TestCase
  test 'should get home' do
    get :home
    assert_response :success
  end

  test 'should get help' do
    skip 'the view is not implemented!'
    get :help
    assert_response :success
  end

  test 'should get video' do
    get :video
    assert_response :success
  end
end
