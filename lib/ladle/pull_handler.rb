require 'ladle/stewards_file_parser'
require 'ladle/steward_changes_view'

module Ladle
  class PullHandler
    def initialize(client, notifier)
      @client = client
      @notifier = notifier
    end

    def handle(pull_request)
      pr_info = @client.pull_request(pull_request.number)

      pull_request_files = @client.pull_request_files(pull_request.number)

      stewards_registry = {}

      read_current_stewards(stewards_registry, pull_request_files, pr_info.head_sha)
      read_old_stewards(stewards_registry, pull_request_files, pr_info.base_sha)

      stewards_registry = resolve_stewards_scope(stewards_registry, pull_request_files)

      if stewards_registry.empty?
        Rails.logger.info('No stewards found. Doing nothing.')
      else
        Rails.logger.info("Found #{stewards_registry.size} stewards. Notifying.")
        @notifier.notify(stewards_registry)
      end
    end

    private

    def read_current_stewards(registry, pull_request_files, pr_head)
      pull_request_files.directories.each do |directory|
        register_stewards(registry, directory.join('stewards.yml'), pr_head)
      end
    end

    def read_old_stewards(registry, pull_request_files, parent_head)
      pull_request_files.modified_stewards_files.each do |stewards_file_path|
        register_stewards(registry, stewards_file_path, parent_head)
      end
    end

    def register_stewards(registry, stewards_file_path, sha)
      contents = @client.contents(path: stewards_file_path.to_s, ref: sha)
      stewards_file = StewardsFileParser.parse(contents)

      stewards_file.stewards.each do |steward_config|
        registry[steward_config.github_username] ||= {}

        changes_view = Ladle::StewardChangesView.new(stewards_file: stewards_file_path,
                                                     file_filter: steward_config.file_filter)

        registry[steward_config.github_username][stewards_file_path.to_s] = [changes_view]
      end
    rescue Ladle::RemoteFileNotFound
      # Ignore - stewards files don't have to exist
    rescue StewardsFileParser::ParsingError => e
      Rails.logger.error("Error parsing file #{stewards_file_path}: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    def select_non_empty_change_views(stewards_file_map, pull_request_files)
      stewards_file_map.reject do |stewards_file_path, change_views|
        change_view = change_views.first
        file_changes = pull_request_files.file_changes_in(change_view.stewards_file.dirname)
        change_view.add_file_changes(file_changes)
        change_view.empty?
      end
    end

    def resolve_stewards_scope(stewards_registry, pull_request_files)
      output = {}

      stewards_registry.each do |github_username, stewards_file_map|
        non_empty_file_map = select_non_empty_change_views(stewards_file_map, pull_request_files)

        unless non_empty_file_map.empty?
          output[github_username] = non_empty_file_map
        end
      end

      output
    end
  end
end
