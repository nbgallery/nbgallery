require 'test_helper'

# :nodoc:
class PreferencesControllerTest < ActionController::TestCase
  setup do
    @preference = preferences(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:preference)
  end

  test 'should create preference' do
    post :create, params: { preference: {} }
    assert_response :success
  end
end
