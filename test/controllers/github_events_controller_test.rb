require 'test_helper'
require 'ladle/test_data'

class GithubEventsControllerTest < ActionController::TestCase

  test "payloads with invalid signatures are processed" do
    repository = create_repository

    Ladle::PullHandler.any_instance.expects(:handle).returns({})

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

  test 'repository does not exist' do
    post :payload, {}.to_json, format: :json, number: 1, pull_request: { state: 'open' }, repository: { full_name: 'test/test' }

    assert_response :forbidden
  end

  test 'open pull request is handled and stewards are notified' do
    repository = create_repository

    stewards_map = Ladle::TestData.create_stewards_map

    Ladle::PullHandler.any_instance.expects(:handle).with(all_of(
                                         is_a(PullRequest),
                                         responds_with(:number, 5),
                                         responds_with(:html_url, 'www.test.com'),
                                         responds_with(:title, 'Hello Dude'),
                                         responds_with(:body, "We did it!"),
                                       )).returns(stewards_map)

    Ladle::StewardNotifier.any_instance.expects(:notify).with(stewards_map)

    @controller.expects(:verify_signature)

    assert_difference('PullRequest.count') do
      post :payload, {}.to_json,
           format:       :json,
           number:       5,
           pull_request: {
             state:    'open',
             html_url: 'www.test.com',
             title:    'Hello Dude',
             body:     "We did it!"
           },
           repository:   {full_name: repository.name}
    end

    assert_response :success
  end

  test "open pull request is handled but doesn't notify if there are no stewards" do
    repository = create_repository

    Ladle::PullHandler.any_instance.expects(:handle).returns({})
    Ladle::StewardNotifier.any_instance.expects(:notify).never

    @controller.expects(:verify_signature)

    Rails.logger.expects(:info).with("New pull #5 for #{repository.name}. Running handler...")
    Rails.logger.expects(:info).with('No stewards found. Doing nothing.')

    assert_difference('PullRequest.count') do
      post :payload, {}.to_json,
           format:       :json,
           number:       5,
           pull_request: {
             state:    'open',
             html_url: 'www.test.com',
             title:    'Hello Dude',
             body:     "We did it!"
           },
           repository:   {full_name: repository.name}
    end

    assert_response :success
  end

  test 'does nothing when pull closed' do
    repository = create_repository

    payload = {}.to_json
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), repository.webhook_secret, payload)
    request.headers['HTTP_X_HUB_SIGNATURE'] = signature

    Ladle::PullHandler.expects(:new).never
    assert_no_difference('PullRequest.count') do
      post :payload, payload, format: :json, number: 5, pull_request: { state: 'closed' }, repository: { full_name: repository.name }
    end

    assert_response :success
  end

  test 'already-recorded pull requests are updated' do
    repository = create_repository

    pull_request = create(:pull_request, repository: repository, number: 5, body: "old description", title: "old title")

    Ladle::PullHandler.any_instance.expects(:handle).returns({})

    @controller.expects(:verify_signature)

    assert_no_difference('PullRequest.count') do
      post :payload, {}.to_json,
           format:       :json,
           number:       pull_request.number,
           pull_request: {
             state:    'open',
             html_url: pull_request.html_url,
             title:    'Hello Dude',
             body:     "We did it!"
           },
           repository:   {full_name: repository.name}
    end

    assert_response :success

    pull_request.reload

    assert_equal 'Hello Dude', pull_request.title
    assert_equal 'We did it!', pull_request.body
  end

  private

  def create_repository
    user = create(:user)
    Repository.create!(name: 'test/test', webhook_secret: 'whatever', access_via: user)
  end
end
