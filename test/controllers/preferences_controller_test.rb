require 'test_helper'

# :nodoc:
class PreferencesControllerTest < ActionController::TestCase
  setup do
    @preference = preferences(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:preferences)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create preference' do
    assert_difference('Preference.count') do
      post :create, params: { preference: { service: @preference.service, url: @preference.url, user_id: @preference.user_id } }
    end

    assert_redirected_to preference_path(assigns(:preference))
  end

  test 'should show preference' do
    get :show, params: { id: @preference }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @preference }
    assert_response :success
  end

  test 'should update preference' do
    patch :update, params: { id: @preference, preference: { service: @preference.service, url: @preference.url, user_id: @preference.user_id } }
    assert_redirected_to preference_path(assigns(:preference))
  end

  test 'should destroy preference' do
    assert_difference('Preference.count', -1) do
      delete :destroy, params: { id: @preference }
    end

    assert_redirected_to preferences_path
  end
end
