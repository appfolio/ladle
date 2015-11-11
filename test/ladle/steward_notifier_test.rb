require 'test_helper'
require 'steward_notifier'

class StewardNotifierTest < ActionController::TestCase
  include VCRHelpers

  setup do
    @stewards = {
      'xanderstrike' => ['/stewards.yml', '/test/stewards.yml'],
      'counterstrike'=> ['/stewards.yml'],
      'boop'         => ['/stewards.yml']
    }
    @pull_request = create(:pull_request, html_url: 'https://github.com/XanderStrike/test/pull/11')
    @notifier = StewardNotifier.new(@stewards, 'XanderStrike/test', @pull_request)
  end

  test 'assigns the stewards and the handler' do
    assert_equal @stewards, @notifier.instance_variable_get(:@stewards_map)
    assert_equal @pull_request, @notifier.instance_variable_get(:@pull_request)
  end

  test 'notify' do
    user = create(:user, email: 'xander@strike.com', github_username: 'xanderstrike')
    @notifier.expects(:send_email).with(user, ['/stewards.yml', '/test/stewards.yml'])
    @notifier.expects(:create_notification).with([user])
    @notifier.notify
  end

  test 'notify - error records notifications for non errored notifications' do
    user1 = create(:user, email: 'xander@strike.com', github_username: 'xanderstrike')
    user2 = create(:user, email: 'counter@strike.com', github_username: 'counterstrike')

    error = RuntimeError.new("Oh no!")

    @notifier.expects(:send_email).with(user1, anything)
    @notifier.expects(:send_email).with(user2, anything).raises(error)
    @notifier.expects(:create_notification).with([user1])

    raised = assert_raises(error.class) do
      @notifier.notify
    end

    assert_equal error, raised
  end

  test 'send_email uses UserMailer' do
    ActionMailer::Base.deliveries.clear
    user = create(:user, email: 'hello@kitty.com')

    @notifier.send(:send_email, user, ['/stewards.yml', '/test/stewards.yml'])

    notify_email = ActionMailer::Base.deliveries.last

    assert_equal "[XanderStrike/test] Ladle Alert: New Pull Request", notify_email.subject
    assert_equal 'hello@kitty.com', notify_email.to[0]
  end

  test 'create_notification' do
    user1 = create(:user)
    user2 = create(:user)

    notification = nil
    assert_difference('Notification.count') do
      notification = @notifier.send(:create_notification, [user1, user2])
    end

    assert_equal @pull_request, notification.pull_request
    assert_equal [user1, user2], notification.notified_users
  end

  test 'create_notification - empty' do
    notification = nil
    assert_no_difference('Notification.count') do
      notification = @notifier.send(:create_notification, [])
    end

    assert_equal nil, notification
  end
end
