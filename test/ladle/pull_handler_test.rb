require 'test_helper'
require 'pull_handler'

class PullHandlerTest < ActiveSupport::TestCase
  include VCRHelpers

  setup do
    user = create(:user)
    @repository = Repository.create!(name: 'xanderstrike/test', webhook_secret: 'whatever', access_via: user)
  end

  test 'creates PullRequest' do
    ph = nil
    assert_difference('PullRequest.count', 1) do
      ph = PullHandler.new(repository: @repository, pull_request_data: {number: 1, html_url: 'www.test.com'})
    end

    assert_equal @repository, ph.instance_variable_get('@repository')

    pull_request = ph.instance_variable_get('@pull_request')
    assert_equal 1, pull_request.number
    assert_equal 'www.test.com', pull_request.html_url
  end

  test 'does nothing when there are not stewards' do
    using_vcr do
      PullHandler.new(repository: @repository, pull_request_data: {number: 1, html_url: 'www.test.com'}).handle
    end
  end

  test 'does nothing when pull already handled' do
    PullRequest.create!(repository: @repository, number: 1, html_url: 'www.test.com', handled: true)

    Rails.logger.expects(:info).with('Pull already handled, skipping.')
    PullHandler.new(repository: @repository, pull_request_data: {number: 1, html_url: 'www.test.com'}).handle
  end

  test 'creates a pull request object if it does not already exist' do
    pull_request_data = {number: 30, html_url: 'www.test.com'}

    mock_notifier = mock
    mock_notifier.expects(:notify)
    StewardNotifier.expects(:new)
      .with({'xanderstrike'                   => ['/stewards.yml'],
             'fadsfadsfadsfadsf'              => ['/stewards.yml'],
             'alexander.standke@appfolio.com' => ['/stewards.yml'],
             'xanderstrike@gmail.com'         => ['/stewards.yml']},
            @repository.name,
            all_of(
              is_a(PullRequest),
              responds_with(:number, pull_request_data[:number]),
              responds_with(:html_url, pull_request_data[:html_url])
            )
      )
      .returns(mock_notifier)

    using_vcr do
      assert_difference('PullRequest.count', 1) do
        PullHandler.new(repository: @repository, pull_request_data: pull_request_data).handle
      end
    end
  end
end
