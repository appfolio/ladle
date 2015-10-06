require 'test_helper'

class GithubEventsControllerTest < ActionController::TestCase
  test "should get payload" do

    data = {payload: {hello: "world"}}

    payload = data.to_json
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.application.github_secret_token, payload)

    request.headers['HTTP_X_HUB_SIGNATURE'] = signature

    post :payload, payload, format: :json
    assert_response :success
  end

  test "invalid signature" do
    data = {payload: {hello: "world"}}

    payload = data.to_json

    request.headers['HTTP_X_HUB_SIGNATURE'] = "stuff!"

    post :payload, payload, format: :json
    assert_response :forbidden
  end

end
