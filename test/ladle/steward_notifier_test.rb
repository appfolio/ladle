require 'test_helper'
require 'ladle/steward_notifier'

require 'ladle/test_data'

class StewardNotifierTest < ActionController::TestCase
  setup do
    @steward_changes_views = Ladle::TestData.create_stewards_map
    @pull_request = create(:pull_request, html_url: 'https://github.com/XanderStrike/test/pull/11')
    @notifier = Ladle::StewardNotifier.new('XanderStrike/test', @pull_request)
  end

  test 'assigns the pull request' do
    assert_equal @pull_request, @notifier.instance_variable_get(:@pull_request)
  end

  test 'notify' do
    user = create(:user, github_username: 'xanderstrike')
    @notifier.expects(:send_email).with(user, @steward_changes_views['xanderstrike'])
    @notifier.expects(:create_notification).with([user])
    @notifier.notify(@steward_changes_views)
  end

  test 'notify - github username is an array' do
    stewards_map_with_array_github_username = Ladle::TestData.create_stewards_map_with_array_github_username
    user1 = create(:user, github_username: 'xanderstrike')
    user2 = create(:user, github_username: 'counterstrike')
    @notifier.expects(:send_email).with(user1, @steward_changes_views['xanderstrike'])
    @notifier.expects(:send_email).with(user2, @steward_changes_views['counterstrike'])
    @notifier.expects(:create_notification).with([user1, user2])

    @notifier.notify(stewards_map_with_array_github_username)
  end

  test 'notify - error records notifications for non errored notifications' do
    user1 = create(:user, github_username: 'xanderstrike')
    user2 = create(:user, github_username: 'counterstrike')

    error = RuntimeError.new("Oh no!")

    @notifier.expects(:send_email).with(user1, anything)
    @notifier.expects(:send_email).with(user2, anything).raises(error)
    @notifier.expects(:create_notification).with([user1])

    raised = assert_raises(error.class) do
      @notifier.notify(@steward_changes_views)
    end

    assert_equal error, raised
  end

  test 'notify - avoid duplicate notifications' do
    user = create(:user, github_username: 'xanderstrike')
    notified_user = create(:user, github_username: 'counterstrike')

    notification = create(:notification, pull_request: @pull_request)
    notification.notified_users << notified_user
    notification.save!

    @notifier.expects(:send_email).with(user, @steward_changes_views['xanderstrike'])
    @notifier.expects(:create_notification).with([user])
    @notifier.notify(@steward_changes_views)
  end

  test 'send_email uses UserMailer' do
    ActionMailer::Base.deliveries.clear
    user = create(:user, email: 'hello@kitty.com')

    @notifier.send(:send_email, user, @steward_changes_views['xanderstrike'])

    notify_email = ActionMailer::Base.deliveries.last

    assert_equal "[XanderStrike/test] Ladle Alert: Change up the World War Z.", notify_email.subject
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

    assert_nil notification
  end
end
