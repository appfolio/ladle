require 'test_helper'
require 'steward_notifier'

class StewardNotifierTest < ActionController::TestCase
  setup do
    @stewards_change_sets = {
      'xanderstrike' => create_steward_change_sets,
      'counterstrike'=> create_steward_change_sets,
      'boop'         => create_steward_change_sets
    }
    @pull_request = create(:pull_request, html_url: 'https://github.com/XanderStrike/test/pull/11')
    @notifier = StewardNotifier.new('XanderStrike/test', @pull_request)
  end

  test 'assigns the handler' do
    assert_equal @pull_request, @notifier.instance_variable_get(:@pull_request)
  end

  test 'notify' do
    user = create(:user, github_username: 'xanderstrike')
    @notifier.expects(:send_email).with(user, @stewards_change_sets['xanderstrike'])
    @notifier.expects(:create_notification).with([user])
    @notifier.notify(@stewards_change_sets)
  end

  test 'notify - error records notifications for non errored notifications' do
    user1 = create(:user, github_username: 'xanderstrike')
    user2 = create(:user, github_username: 'counterstrike')

    error = RuntimeError.new("Oh no!")

    @notifier.expects(:send_email).with(user1, anything)
    @notifier.expects(:send_email).with(user2, anything).raises(error)
    @notifier.expects(:create_notification).with([user1])

    raised = assert_raises(error.class) do
      @notifier.notify(@stewards_change_sets)
    end

    assert_equal error, raised
  end

  test 'notify - avoid duplicate notifications' do
    user = create(:user, github_username: 'xanderstrike')
    notified_user = create(:user, github_username: 'counterstrike')

    notification = create(:notification, pull_request: @pull_request)
    notification.notified_users << notified_user
    notification.save!

    @notifier.expects(:send_email).with(user, @stewards_change_sets['xanderstrike'])
    @notifier.expects(:create_notification).with([user])
    @notifier.notify(@stewards_change_sets)
  end

  test 'send_email uses UserMailer' do
    ActionMailer::Base.deliveries.clear
    user = create(:user, email: 'hello@kitty.com')

    @notifier.send(:send_email, user, @stewards_change_sets['xanderstrike'])

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

    assert_equal nil, notification
  end

  private

  def create_steward_change_sets
    [
      Ladle::StewardsFileChangeSet.new('app/stewards.yml',
                                       [
                                         Ladle::FileChange.new(:removed, "app/removed_file.rb"),
                                         Ladle::FileChange.new(:modified, "app/modified_file.rb"),
                                         Ladle::FileChange.new(:added, "app/new_file.rb"),
                                       ]),
      Ladle::StewardsFileChangeSet.new('lib/closet/stewards.yml',
                                       [
                                         Ladle::FileChange.new(:added, "lib/closet/top_shelf/new_file.rb"),
                                       ]),
    ]
  end
end
