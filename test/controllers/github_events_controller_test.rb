require 'test_helper'

class GithubEventsControllerTest < ActionController::TestCase
  test 'should get payload' do
    repository = Repository.create!(name: 'test/test', webhook_secret: 'whatever', access_token: 'hey')

    PullHandler.any_instance.stubs(:handle)

    payload = {}.to_json
    signature = repository.compute_webhook_signature(payload)

    request.headers['HTTP_X_HUB_SIGNATURE'] = signature

    post :payload, payload, format: :json, number: 1, pull_request: { state: 'open' }, repository: { full_name: 'test/test' }
    assert_response :success
  end

  test 'invalid signature' do
    Repository.create!(name: 'test/test', webhook_secret: 'whatever', access_token: 'hey')

    payload = {}.to_json
    request.headers['HTTP_X_HUB_SIGNATURE'] = 'stuff!'
    post :payload, payload, format: :json, number: 1, pull_request: { state: 'open' }, repository: { full_name: 'test/test' }

    assert_response :forbidden
  end

  test 'repository does not exist' do
    post :payload, {}.to_json, format: :json, number: 1, pull_request: { state: 'open' }, repository: { full_name: 'test/test' }

    assert_response :forbidden
  end

  test 'handles the pull when opened' do
    repository = Repository.create!(name: 'test/test', webhook_secret: 'whatever', access_token: 'hey')

    handler_mock = mock
    handler_mock.expects(:handle)
    PullHandler.expects(:new).with(repository: repository, number: 5, html_url: 'www.test.com').returns(handler_mock)

    @controller.expects(:verify_signature)
    post :payload, {}.to_json, format: :json, number: 5, pull_request: { state: 'open', html_url: 'www.test.com' }, repository: { full_name: 'test/test' }

    assert_response :success
  end

  test 'does nothing when pull closed' do
    repository = Repository.create!(name: 'test/test', webhook_secret: 'whatever', access_token: 'hey')
    PullHandler.expects(:new).never

    payload = {}.to_json
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), repository.webhook_secret, payload)
    request.headers['HTTP_X_HUB_SIGNATURE'] = signature
    post :payload, payload, format: :json, number: 5, pull_request: { state: 'closed' }, repository: { full_name: 'test/test' }

    assert_response :success
  end

  test 'required parameters repository' do
    raised = assert_raises(ActionController::ParameterMissing) do
      post :payload, {}.to_json, format: :json, number: 5, pull_request: { }
    end

    assert_equal :repository, raised.param
  end

  test 'required parameters pull_request' do
    Repository.create!(name: 'test/test', webhook_secret: 'whatever', access_token: 'hey')

    @controller.expects(:verify_signature)

    raised = assert_raises(ActionController::ParameterMissing) do
      post :payload, {}.to_json, format: :json, number: 5, repository: { full_name: 'test/test' }
    end

    assert_equal :pull_request, raised.param
  end
end
