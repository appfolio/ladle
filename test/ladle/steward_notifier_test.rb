require 'test_helper'
require 'pull_handler'
require 'steward_notifier'

class StewardNotifierTest < ActionController::TestCase
  include VCRHelpers

  setup do
    @pull_handler = PullHandler.new(number: 11, repo: 'XanderStrike/test', html_url: 'https://github.com/XanderStrike/test/pull/11')
    @stewards     = ['xanderstrike', 'boop']
  end

  test 'assigns the stewards and the handler' do
    sn = StewardNotifier.new(@stewards, @pull_handler)
    assert_equal @stewards, sn.instance_variable_get('@stewards')
    assert_equal @pull_handler, sn.instance_variable_get('@handler')
  end

  test 'notify should send emails to users' do
    User.create!(email: 'xander@strike.com', password: 'blehbleh', provider: "bleh", uid: "123", token: 'a', github_username: 'xanderstrike')
    sn = StewardNotifier.new(@stewards, @pull_handler)

    sn.expects(:send_email).with('xander@strike.com')
    sn.notify
  end

  test 'send_email uses UserMailer' do
    sn = StewardNotifier.new(@stewards, @pull_handler)
    sn.send(:send_email, "hello@kitty.com")


    notify_email = ActionMailer::Base.deliveries.last

    assert_equal "Ladle: New PR", notify_email.subject
    assert_equal 'hello@kitty.com', notify_email.to[0]
  end
end
