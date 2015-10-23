require 'test_helper'

class PullRequestsControllerTest < ActionController::TestCase
  setup do
    @pull_request = pull_requests(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pull_requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pull_request" do
    assert_difference('PullRequest.count') do
      post :create, pull_request: {  }
    end

    assert_redirected_to pull_request_path(assigns(:pull_request))
  end

  test "should show pull_request" do
    get :show, id: @pull_request
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @pull_request
    assert_response :success
  end

  test "should update pull_request" do
    patch :update, id: @pull_request, pull_request: {  }
    assert_redirected_to pull_request_path(assigns(:pull_request))
  end

  test "should destroy pull_request" do
    assert_difference('PullRequest.count', -1) do
      delete :destroy, id: @pull_request
    end

    assert_redirected_to pull_requests_path
  end
end
