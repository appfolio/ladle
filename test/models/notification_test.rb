require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test "belongs_to PullRequest" do
    notification = Notification.create
    refute_predicate notification, :valid?
    assert_equal({ pull_request: ["can't be blank"] }, notification.errors.messages)

    notification.pull_request = create(:pull_request)
    assert_predicate notification, :valid?
  end

  test "has_and_belongs_to_many :notified_users" do
    notification = Notification.create!(pull_request: create(:pull_request))
    users = [
      create(:user),
      create(:user),
    ]

    users.each do |user|
      notification.notified_users << user
    end

    notification.save!
    users.map(&:reload)

    assert_equal users, notification.notified_users

    users.each do |user|
      assert_equal notification, user.notifications.first
    end
  end
end
