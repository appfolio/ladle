require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test "belongs_to PullRequest" do
    notification = Notification.create
    refute_predicate notification, :valid?
    assert_equal({ pull_request: ["can't be blank"] }, notification.errors.messages)

    notification.pull_request = create(:pull_request)
    assert_predicate notification, :valid?
  end
end
