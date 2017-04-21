require 'test_helper'

# :nodoc:
class GroupsControllerTest < ActionController::TestCase
  setup do
    @group = groups(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:groups)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create group' do
    assert_difference('Group.count') do
      post :create, params: { group: { description: @group.description, gid: @group.gid, landing_id: @group.landing_id, name: @group.name, url: @group.url } }
    end

    assert_redirected_to group_path(assigns(:group))
  end

  test 'should show group' do
    get :show, params: { id: @group }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @group }
    assert_response :success
  end

  test 'should update group' do
    patch :update, params: { id: @group, group: { description: @group.description, gid: @group.gid, landing_id: @group.landing_id, name: @group.name, url: @group.url } }
    assert_redirected_to group_path(assigns(:group))
  end

  test 'should destroy group' do
    assert_difference('Group.count', -1) do
      delete :destroy, params: { id: @group }
    end

    assert_redirected_to groups_path
  end
end
