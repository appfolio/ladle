require 'test_helper'
require 'ladle/notify_stewards_of_pull_request_changes'
require 'ladle/github_repository_client'
require 'ladle/test_data'

class NotifyStewardsOfPullRequestChangesTest < ActiveSupport::TestCase

  setup do
    @pull_request = create(:pull_request)
  end

  test "PullRequestChangeCollector uses github client" do
    collector_mock = mock
    collector_mock.expects(:collect_changes).returns({})

    Ladle::PullRequestChangeCollector.expects(:new).with(is_a(Ladle::GithubRepositoryClient)).returns(collector_mock)

    Ladle::NotifyStewardsOfPullRequestChanges.call(@pull_request)
  end

  test 'open pull request is handled and stewards are notified' do
    stewards_map = Ladle::TestData.create_stewards_map

    Ladle::PullRequestChangeCollector.any_instance.expects(:collect_changes).with(@pull_request).returns(stewards_map)
    Ladle::StewardNotifier.any_instance.expects(:notify).with(stewards_map)

    Rails.logger.expects(:info).with("Found #{stewards_map.size} stewards. Notifying.")

    Ladle::NotifyStewardsOfPullRequestChanges.call(@pull_request)
  end

  test "open pull request is handled but doesn't notify if there are no stewards" do
    Ladle::PullRequestChangeCollector.any_instance.expects(:collect_changes).returns({})
    Ladle::StewardNotifier.any_instance.expects(:notify).never

    Rails.logger.expects(:info).with('No stewards found. Doing nothing.')

    Ladle::NotifyStewardsOfPullRequestChanges.call(@pull_request)
  end
end
