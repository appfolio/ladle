require 'test_helper'

class PullRequestsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    sign_in @user
    @pull_request = PullRequest.create!(number: 11, repo: 'XanderStrike/test', html_url: 'https://github.com/XanderStrike/test/pull/11')
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:pull_requests)
  end

  test 'should show pull_request' do
    get :show, id: @pull_request
    assert_response :success
  end

  test 'should destroy pull_request' do
    assert_difference('PullRequest.count', -1) do
      delete :destroy, id: @pull_request
    end

    assert_redirected_to pull_requests_path
  end
end
