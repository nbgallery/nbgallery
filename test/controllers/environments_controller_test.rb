require 'test_helper'

# :nodoc:
class EnvironmentsControllerTest < ActionController::TestCase
  setup do
    @environment = environments(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:environments)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create environment' do
    assert_difference('Environment.count') do
      post :create, params: { environment: { default: @environment.default, name: @environment.name, url: @environment.url, user_id: @environment.user_id } }
    end

    assert_redirected_to environment_path(assigns(:environment))
  end

  test 'should show environment' do
    get :show, params: { id: @environment }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @environment }
    assert_response :success
  end

  test 'should update environment' do
    patch :update, params: { id: @environment, environment: { default: @environment.default, name: @environment.name, url: @environment.url, user_id: @environment.user_id } }
    assert_redirected_to environment_path(assigns(:environment))
  end

  test 'should destroy environment' do
    assert_difference('Environment.count', -1) do
      delete :destroy, params: { id: @environment }
    end

    assert_redirected_to environments_path
  end
end
