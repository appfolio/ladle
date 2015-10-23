require 'test_helper'
require 'pull_handler'
require 'steward_notifier'

class StewardNotifierTest < ActionController::TestCase
  include VCRHelpers

  setup do
    @pull_handler = PullHandler.new(number: 11, repo: 'XanderStrike/test', html_url: 'https://github.com/XanderStrike/test/pull/11')
    @stewards = ['xanderstrike', 'xanderstrike@gmail.com', 'boop', 'test@test.com']
  end

  test 'assigns the stewards and the handler' do
    sn = StewardNotifier.new(@stewards, @pull_handler)
    assert_equal @stewards, sn.instance_variable_get('@stewards')
    assert_equal @pull_handler, sn.instance_variable_get('@handler')
  end

  test 'comments on github' do
    using_vcr do
      sn = StewardNotifier.new(%w(xanderstrike kimboslice), @pull_handler)
      sn.stubs(:notify_emails)
      sn.notify
    end
  end

  test 'sends emails' do
    mailer = UserMailer.notify('test@test.com', 'test.com')
    sn = StewardNotifier.new(@stewards, @pull_handler)
    sn.stubs(:notify_github)
    UserMailer.expects(:notify).twice.returns(mailer)

    sn.notify
  end
end
