require 'test_helper'
require 'pull_handler'

class PullHandlerTest < ActiveSupport::TestCase
  include VCRHelpers

  setup do
    user = User.create!(email: 'test@test.com', password: 'hunter234')
    @repository = Repository.create!(name: 'xanderstrike/test', webhook_secret: 'whatever', access_via: user)
  end

  test 'stores the repo and number' do
    ph = PullHandler.new(repository: @repository, number: 1, html_url: 'www.test.com')
    assert_equal @repository, ph.instance_variable_get('@repository')
    assert_equal 1, ph.instance_variable_get('@number')
    assert_equal 'www.test.com', ph.instance_variable_get('@html_url')
  end

  test 'does nothing when there are not stewards' do
    using_vcr do
      PullHandler.new(repository: @repository, number: 1, html_url: 'www.test.com').handle
    end
  end

  test 'does nothing when pull already handled' do
    PullRequest.create!(repo: 'xanderstrike/test', number: 1, html_url: 'www.test.com', handled: true)

    Rails.logger.expects(:info).with('Pull already handled, skipping.')
    PullHandler.new(repository: @repository, number: 1, html_url: 'www.test.com').handle
  end

  test 'creates a pull request object if it does not already exist' do
    mock_notifier = mock
    mock_notifier.expects(:notify)
    StewardNotifier.expects(:new)
      .with({'xanderstrike' => ['/stewards.yml'],
             'fadsfadsfadsfadsf' => ['/stewards.yml'],
             'alexander.standke@appfolio.com' => ['/stewards.yml'],
             'xanderstrike@gmail.com' => ['/stewards.yml']}, 'www.test.com')
      .returns(mock_notifier)

    using_vcr do
      assert_difference('PullRequest.count', 1) do
        PullHandler.new(repository: @repository, number: 30, html_url: 'www.test.com').handle
      end
    end
  end
end
