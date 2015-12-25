require 'ladle/github_repository_client'
require 'ladle/pull_request_change_collector'
require 'ladle/steward_notifier'

module Ladle
  class NotifyStewardsOfPullRequestChanges

    def self.call(pull_request)
      github_client = Ladle::GithubRepositoryClient.new(pull_request.repository)
      collector = Ladle::PullRequestChangeCollector.new(github_client)

      stewards_changes_map = collector.collect_changes(pull_request)

      if stewards_changes_map.empty?
        Rails.logger.info('No stewards found. Doing nothing.')
      else
        Rails.logger.info("Found #{stewards_changes_map.size} stewards. Notifying.")
        notifier = Ladle::StewardNotifier.new(pull_request.repository.name, pull_request)
        notifier.notify(stewards_changes_map)
      end
    end
  end
end
