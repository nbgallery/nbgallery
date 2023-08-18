require 'test_helper'

# :nodoc:
class TagsControllerTest < ActionController::TestCase
  setup do
    @tag = tags(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:tag_text_with_counts)
  end

  test 'should show tag' do
    get :show, params: { id: @tag }
    assert_response :success
  end
end
