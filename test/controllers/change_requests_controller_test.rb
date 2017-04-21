require 'test_helper'

# :nodoc:
class ChangeRequestsControllerTest < ActionController::TestCase
  setup do
    @change_request = change_requests(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:change_requests)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create change_request' do
    assert_difference('ChangeRequest.count') do
      post :create, params: { change_request: { notebook_id: @change_request.notebook_id, owner_comment: @change_request.owner_comment, reqid: @change_request.reqid, requestor_comment: @change_request.requestor_comment, requestor_id: @change_request.requestor_id, status: @change_request.status } }
    end

    assert_redirected_to change_request_path(assigns(:change_request))
  end

  test 'should show change_request' do
    get :show, params: { id: @change_request }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @change_request }
    assert_response :success
  end

  test 'should update change_request' do
    patch :update, params: { id: @change_request, change_request: { notebook_id: @change_request.notebook_id, owner_comment: @change_request.owner_comment, reqid: @change_request.reqid, requestor_comment: @change_request.requestor_comment, requestor_id: @change_request.requestor_id, status: @change_request.status } }
    assert_redirected_to change_request_path(assigns(:change_request))
  end

  test 'should destroy change_request' do
    assert_difference('ChangeRequest.count', -1) do
      delete :destroy, params: { id: @change_request }
    end

    assert_redirected_to change_requests_path
  end
end
