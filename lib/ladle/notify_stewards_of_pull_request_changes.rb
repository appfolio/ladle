require 'ladle/github_repository_client'
require 'ladle/pull_handler'
require 'ladle/steward_notifier'

module Ladle
  class NotifyStewardsOfPullRequestChanges

    def self.call(pull_request)
      github_client = Ladle::GithubRepositoryClient.new(pull_request.repository)
      pull_handler = Ladle::PullHandler.new(github_client)

      stewards_registry = pull_handler.handle(pull_request)

      if stewards_registry.empty?
        Rails.logger.info('No stewards found. Doing nothing.')
      else
        Rails.logger.info("Found #{stewards_registry.size} stewards. Notifying.")
        notifier = Ladle::StewardNotifier.new(pull_request.repository.name, pull_request)
        notifier.notify(stewards_registry)
      end
    end
  end
end
