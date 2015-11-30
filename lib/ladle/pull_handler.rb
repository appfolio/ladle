require 'ladle/changed_files'
require 'ladle/stewards_file_parser'

module Ladle
  class PullHandler
    def initialize(pull_request, notifier)
      @pull_request = pull_request
      @repository   = pull_request.repository

      @notifier = notifier
    end

    def handle
      client = Octokit::Client.new(access_token: @repository.access_token)

      pr_info = fetch_pr_info(client)

      pull_request_files = fetch_changed_files(client)

      stewards_registry = {}

      read_current_stewards(client, stewards_registry, pull_request_files, pr_info.head_sha)
      read_old_stewards(client, stewards_registry, pull_request_files, pr_info.base_sha)

      collect_files(stewards_registry, pull_request_files)

      if stewards_registry.empty?
        Rails.logger.info('No stewards found. Doing nothing.')
      else
        Rails.logger.info("Found #{stewards_registry.size} stewards. Notifying.")
        @notifier.notify(stewards_registry)
      end
    end

    private

    PullRequestInfo = Struct.new(:head_sha, :base_sha)

    def fetch_pr_info(client)
      pr = client.pull_request(@repository.name, @pull_request.number)
      PullRequestInfo.new(pr[:head][:sha], pr[:base][:sha])
    end

    def fetch_changed_files(client)
      changed_files = ChangedFiles.new

      client.pull_request_files(@repository.name, @pull_request.number).each do |file|
        file_change = Ladle::FileChange.new(
          status:    file[:status].to_sym,
          file:      file[:filename],
          additions: file[:additions],
          deletions: file[:deletions]
        )
        changed_files.add_file_change(file_change)
      end

      changed_files
    end

    def read_current_stewards(client, registry, pull_request_files, pr_head)
      pull_request_files.directories.each do |directory|
        register_stewards(client, registry, directory.join('stewards.yml'), pr_head)
      end
    end

    def read_old_stewards(client, registry, pull_request_files, parent_head)
      pull_request_files.modified_stewards_files.each do |stewards_file_path|
        register_stewards(client, registry, stewards_file_path, parent_head)
      end
    end

    def register_stewards(client, registry, stewards_file_path, sha)
      contents = client.contents(@repository.name, path: stewards_file_path.to_s, ref: sha)[:content]
      stewards_file = StewardsFileParser.parse(Base64.decode64(contents))

      stewards_file.stewards.each do |steward_config|
        registry[steward_config.github_username] ||= []

        changes_view = Ladle::StewardChangesView.new(stewards_file: stewards_file_path,
                                                     file_filter: steward_config.file_filter)

        registry[steward_config.github_username] << changes_view
      end
    rescue Octokit::NotFound
      # Ignore - stewards files don't have to exist
    rescue StewardsFileParser::ParsingError => e
      Rails.logger.error("Error parsing file #{stewards_file_path}: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    def collect_files(stewards_registry, pull_request_files)
      stewards_registry.each_value do |steward_change_views|
        steward_change_views.each do |change_view|
          file_changes = pull_request_files.file_changes_in(change_view.stewards_file.dirname)
          change_view.add_file_changes(file_changes)
        end
      end
    end
  end
end
