require 'test_helper'
require 'pull_handler'

class PullHandlerTest < ActiveSupport::TestCase
  include VCRHelpers

  test 'stores the repo and number' do
    ph = PullHandler.new(repo: 'a', number: 1, html_url: 'www.test.com')
    assert_equal 'a', ph.instance_variable_get('@repo')
    assert_equal 1, ph.instance_variable_get('@number')
    assert_equal 'www.test.com', ph.instance_variable_get('@html_url')
  end

  test 'gets the stewards and posts a comment' do
    mock_notifier = mock
    mock_notifier.expects(:notify)
    StewardNotifier.expects(:new)
      .with(['xanderstrike', 'fadsfadsfadsfadsf', 'alexander.standke@appfolio.com', 'xanderstrike@gmail.com'], anything)
      .returns(mock_notifier)

    using_vcr do
      PullHandler.new(repo: 'XanderStrike/test', number: 30, html_url: 'www.test.com').handle
    end
  end

  test 'does nothing when there are not stewards' do
    using_vcr do
      PullHandler.new(repo: 'XanderStrike/test', number: 1, html_url: 'www.test.com').handle
    end
  end

  test 'does nothing when pull already handled' do
    PullRequest.create!(repo: 'xanderstrike/test', number: 1, html_url: 'www.test.com', handled: true)

    Rails.logger.expects(:info).with('Pull already handled, skipping.')
    PullHandler.new(repo: 'xanderstrike/test', number: 1, html_url: 'www.test.com').handle
  end

  test 'creates a pull request object if it does not already exist' do
    mock_notifier = mock
    mock_notifier.expects(:notify)
    StewardNotifier.expects(:new)
      .with(['xanderstrike', 'fadsfadsfadsfadsf', 'alexander.standke@appfolio.com', 'xanderstrike@gmail.com'], anything)
      .returns(mock_notifier)

    using_vcr do
      assert_difference('PullRequest.count', 1) do
        PullHandler.new(repo: 'xanderstrike/test', number: 30, html_url: 'www.test.com').handle
      end
    end
  end
end
