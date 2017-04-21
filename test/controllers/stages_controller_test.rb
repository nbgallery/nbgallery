require 'test_helper'

# :nodoc:
class StagesControllerTest < ActionController::TestCase
  setup do
    @stage = stages(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:stages)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create stage' do
    assert_difference('Stage.count') do
      post :create, params: { stage: { user_id: @stage.user_id, uuid: @stage.uuid } }
    end

    assert_redirected_to stage_path(assigns(:stage))
  end

  test 'should show stage' do
    get :show, params: { id: @stage }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @stage }
    assert_response :success
  end

  test 'should update stage' do
    patch :update, params: { id: @stage, stage: { user_id: @stage.user_id, uuid: @stage.uuid } }
    assert_redirected_to stage_path(assigns(:stage))
  end

  test 'should destroy stage' do
    assert_difference('Stage.count', -1) do
      delete :destroy, params: { id: @stage }
    end

    assert_redirected_to stages_path
  end
end
