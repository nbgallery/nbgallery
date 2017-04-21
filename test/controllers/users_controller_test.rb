require 'test_helper'

# :nodoc:
class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create user' do
    assert_difference('User.count') do
      post :create, params: { user: { admin: @user.admin, email: @user.email, first_name: @user.first_name, last_name: @user.last_name, org: @user.org } }
    end

    assert_redirected_to user_path(assigns(:user))
  end

  test 'should show user' do
    get :show, params: { id: @user }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @user }
    assert_response :success
  end

  test 'should update user' do
    patch :update, params: { id: @user, user: { admin: @user.admin, email: @user.email, first_name: @user.first_name, last_name: @user.last_name, org: @user.org } }
    assert_redirected_to user_path(assigns(:user))
  end

  test 'should destroy user' do
    assert_difference('User.count', -1) do
      delete :destroy, params: { id: @user }
    end

    assert_redirected_to users_path
  end
end
