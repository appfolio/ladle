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

  test 'handles the pull when opened' do
    repository = create_repository

    handler_mock = mock
    handler_mock.expects(:handle)

    PullHandler.expects(:new).with(all_of(
                                     is_a(PullRequest),
                                     responds_with(:number, 5),
                                     responds_with(:html_url, 'www.test.com'),
                                     responds_with(:title, 'Hello Dude'),
                                     responds_with(:description, "We did it!"),
                                   )).returns(handler_mock)

    @controller.expects(:verify_signature)

    assert_difference('PullRequest.count') do
      post :payload, {}.to_json,
           format:       :json,
           number:       5,
           pull_request: {
             state:       'open',
             html_url:    'www.test.com',
             title:       'Hello Dude',
             description: "We did it!"
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

    PullHandler.expects(:new).never
    assert_no_difference('PullRequest.count') do
      post :payload, payload, format: :json, number: 5, pull_request: { state: 'closed' }, repository: { full_name: repository.name }
    end

    assert_response :success
  end

  test 'handles the pull - updates pull request' do
    repository = create_repository

    pull_request = create(:pull_request, repository: repository, number: 5, description: "old description", title: "old title")

    handler_mock = mock
    handler_mock.expects(:handle)

    PullHandler.expects(:new).with(pull_request).returns(handler_mock)

    @controller.expects(:verify_signature)

    assert_no_difference('PullRequest.count') do
      post :payload, {}.to_json,
           format:       :json,
           number:       pull_request.number,
           pull_request: {
             state:       'open',
             html_url:    pull_request.html_url,
             title:       'Hello Dude',
             description: "We did it!"
           },
           repository:   {full_name: repository.name}
    end

    assert_response :success

    pull_request.reload

    assert_equal 'Hello Dude', pull_request.title
    assert_equal 'We did it!', pull_request.description
  end

  private

  def create_repository
    user = create(:user)
    Repository.create!(name: 'test/test', webhook_secret: 'whatever', access_via: user)
  end
end
