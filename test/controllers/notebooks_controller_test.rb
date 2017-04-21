require 'test_helper'

# :nodoc:
class NotebooksControllerTest < ActionController::TestCase
  setup do
    @notebook = notebooks(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:notebooks)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create notebook' do
    assert_difference('Notebook.count') do
      post :create, params: { notebook: { commit_id: @notebook.commit_id, content_updated_at: @notebook.content_updated_at, creator_id: @notebook.creator_id, description: @notebook.description, lang: @notebook.lang, lang_version: @notebook.lang_version, owner_id: @notebook.owner_id, owner_type: @notebook.owner_type, public: @notebook.public, title: @notebook.title, updater_id: @notebook.updater_id, uuid: @notebook.uuid } }
    end

    assert_redirected_to notebook_path(assigns(:notebook))
  end

  test 'should show notebook' do
    get :show, params: { id: @notebook }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @notebook }
    assert_response :success
  end

  test 'should update notebook' do
    patch :update, params: { id: @notebook, notebook: { commit_id: @notebook.commit_id, content_updated_at: @notebook.content_updated_at, creator_id: @notebook.creator_id, description: @notebook.description, lang: @notebook.lang, lang_version: @notebook.lang_version, owner_id: @notebook.owner_id, owner_type: @notebook.owner_type, public: @notebook.public, title: @notebook.title, updater_id: @notebook.updater_id, uuid: @notebook.uuid } }
    assert_redirected_to notebook_path(assigns(:notebook))
  end

  test 'should destroy notebook' do
    assert_difference('Notebook.count', -1) do
      delete :destroy, params: { id: @notebook }
    end

    assert_redirected_to notebooks_path
  end
end
