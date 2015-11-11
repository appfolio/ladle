require 'test_helper'

class GithubEventsControllerTest < ActionController::TestCase
  test 'should get payload' do
    repository = create_repository

    PullHandler.any_instance.stubs(:handle)

    payload = {}.to_json
    signature = repository.compute_webhook_signature(payload)

    request.headers['HTTP_X_HUB_SIGNATURE'] = signature

    post :payload, payload, format: :json, number: 1, pull_request: { state: 'open' }, repository: { full_name: repository.name }
    assert_response :success
  end

  test 'invalid signature' do
    repository = create_repository

    payload = {}.to_json
    request.headers['HTTP_X_HUB_SIGNATURE'] = 'stuff!'
    post :payload, payload, format: :json, number: 1, pull_request: { state: 'open' }, repository: { full_name: repository.name }

    assert_response :forbidden
  end

  test 'repository does not exist' do
    post :payload, {}.to_json, format: :json, number: 1, pull_request: { state: 'open' }, repository: { full_name: 'test/test' }

    assert_response :forbidden
  end

  test 'handles the pull when opened' do
    repository = create_repository

    handler_mock = mock
    handler_mock.expects(:handle)
    PullHandler.expects(:new).with(repository: repository, pull_request_data: {number: 5, html_url: 'www.test.com', title: 'Hello Dude', description: "We did it!"}).returns(handler_mock)

    @controller.expects(:verify_signature)
    post :payload, {}.to_json, format: :json, number: 5, pull_request: { state: 'open', html_url: 'www.test.com', title: 'Hello Dude', description: "We did it!" }, repository: { full_name: repository.name }

    assert_response :success
  end

  test 'does nothing when pull closed' do
    repository = create_repository

    payload = {}.to_json
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), repository.webhook_secret, payload)
    request.headers['HTTP_X_HUB_SIGNATURE'] = signature

    PullHandler.expects(:new).never
    post :payload, payload, format: :json, number: 5, pull_request: { state: 'closed' }, repository: { full_name: repository.name }

    assert_response :success
  end

  test 'required parameters repository' do
    raised = assert_raises(ActionController::ParameterMissing) do
      post :payload, {}.to_json, format: :json, number: 5, pull_request: { }
    end

    assert_equal :repository, raised.param
  end

  test 'required parameters pull_request' do
    repository = create_repository

    @controller.expects(:verify_signature)

    raised = assert_raises(ActionController::ParameterMissing) do
      post :payload, {}.to_json, format: :json, number: 5, repository: { full_name: repository.name }
    end

    assert_equal :pull_request, raised.param
  end

  private

  def create_repository
    user = create(:user)
    Repository.create!(name: 'test/test', webhook_secret: 'whatever', access_via: user)
  end
end
