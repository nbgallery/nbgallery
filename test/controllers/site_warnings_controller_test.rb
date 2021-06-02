require 'test_helper'

# :nodoc:
class SiteWarningsControllerTest < ActionController::TestCase
  setup do
    @warning = site_warnings(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:warnings)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create site_warning' do
    assert_difference('SiteWarning.count') do
      post :create, params: { warning: { expires: @warning.expires, message: @warning.message, type: @warning.type, user_id: @warning.user_id } }
    end

    assert_redirected_to site_warning_path(assigns(:warning))
  end

  test 'should show site_warning' do
    get :show, params: { id: @warning }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @warning }
    assert_response :success
  end

  test 'should update site_warning' do
    patch :update, params: { id: @warning, warning: { expires: @warning.expires, message: @warning.message, type: @warning.type, user_id: @warning.user_id } }
    assert_redirected_to site_warning_path(assigns(:warning))
  end

  test 'should destroy site_warning' do
    assert_difference('SiteWarning.count', -1) do
      delete :destroy, params: { id: @warning }
    end

    assert_redirected_to site_warning_path
  end
end
