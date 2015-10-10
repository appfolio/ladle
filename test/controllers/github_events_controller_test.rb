require 'test_helper'

class GithubEventsControllerTest < ActionController::TestCase
  test 'should get payload' do
    PullHandler.any_instance.stubs(:handle)
    data = {payload: {hello: 'world'}}

    payload = {}.to_json
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.application.github_secret_token, payload)

    request.headers['HTTP_X_HUB_SIGNATURE'] = signature

    post :payload, payload, format: :json, number: 1, pull_request: { state: 'open' }, repository: { full_name: 'test/test' }
    assert_response :success
  end

  test 'invalid signature' do
    payload = {}.to_json
    request.headers['HTTP_X_HUB_SIGNATURE'] = 'stuff!'
    post :payload, payload, format: :json

    assert_response :forbidden
  end

  test 'handles the pull when opened' do
    handler_mock = PullHandler.new(repo: 'a', number: 1)
    handler_mock.expects(:handle)
    PullHandler.expects(:new).with(repo: 'test/test', number: 5).returns(handler_mock)

    payload = {}.to_json
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.application.github_secret_token, payload)
    request.headers['HTTP_X_HUB_SIGNATURE'] = signature
    post :payload, payload, format: :json, number: 5, pull_request: { state: 'open' }, repository: { full_name: 'test/test' }

    assert_response :success
  end

  test 'does nothing when pull closed' do
    PullHandler.expects(:new).never

    payload = {}.to_json
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.application.github_secret_token, payload)
    request.headers['HTTP_X_HUB_SIGNATURE'] = signature
    post :payload, payload, format: :json, number: 5, pull_request: { state: 'closed' }, repository: { full_name: 'test/test' }

    assert_response :success
  end

  test 'raises invalid request' do
    payload = {}.to_json
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.application.github_secret_token, payload)
    request.headers['HTTP_X_HUB_SIGNATURE'] = signature

    assert_raises(ActionController::ParameterMissing) do
      post :payload, payload, format: :json, number: 5, pull_request: { }, repository: { full_name: 'test/test' }
    end

    assert_raises(ActionController::ParameterMissing) do
      post :payload, payload, format: :json, number: 5, pull_request: { state: 'open' }, repository: { }
    end
  end
end
