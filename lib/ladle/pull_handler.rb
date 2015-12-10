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

      stewards_from_base = read_stewards(pull_request_files, pr_info.base_sha)
      stewards_from_base = resolve_stewards_scope(stewards_from_base, pull_request_files)

      stewards_from_head = read_new_stewards(pull_request_files, pr_info.head_sha)
      stewards_from_head = resolve_stewards_scope(stewards_from_head, pull_request_files)

      stewards_registry = combine_stewards_tree_maps(stewards_from_base, stewards_from_head)

      if stewards_registry.empty?
        Rails.logger.info('No stewards found. Doing nothing.')
      else
        Rails.logger.info("Found #{stewards_registry.size} stewards. Notifying.")
        @notifier.notify(stewards_registry)
      end
    end

    private

    def read_new_stewards(pull_request_files, base_head)
      stewards_user_tree_map = {} #StewardsUserTreeMap.new
      pull_request_files.modified_stewards_files.each do |stewards_file_path|
        register_stewards(stewards_user_tree_map, stewards_file_path, base_head)
      end
      stewards_user_tree_map
    end

    def read_stewards(pull_request_files, pr_head)
      stewards_user_tree_map = {} #StewardsUserTreeMap.new
      pull_request_files.directories.each do |directory|
        register_stewards(stewards_user_tree_map, directory.join('stewards.yml'), pr_head)
      end

      stewards_user_tree_map
    end

    def register_stewards(stewards_user_tree_map, stewards_file_path, sha)
      contents = @client.contents(path: stewards_file_path.to_s, ref: sha)
      stewards_file = StewardsFileParser.parse(contents)

      stewards_file.stewards.each do |steward_config|
        changes_view = Ladle::StewardChangesView.new(stewards_file: stewards_file_path,
                                                     file_filter: steward_config.file_filter)

        stewards_user_tree_map[steward_config.github_username] ||= {}
        stewards_user_tree_map[steward_config.github_username][stewards_file_path.to_s] = [changes_view]
      end
    rescue Ladle::RemoteFileNotFound
      # Ignore - stewards files don't have to exist
    rescue StewardsFileParser::ParsingError => e
      Rails.logger.error("Error parsing file #{stewards_file_path}: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    def select_non_empty_change_views(steward_tree, pull_request_files)
      steward_tree.reject do |stewards_file_path, change_views|
        change_view = change_views.first
        file_changes = pull_request_files.file_changes_in(change_view.stewards_file.dirname)
        change_view.add_file_changes(file_changes)
        change_view.empty?
      end
    end

    def resolve_stewards_scope(stewards_user_tree_map, pull_request_files)
      output = {}

      stewards_user_tree_map.each do |github_username, steward_tree|
        non_empty_file_map = select_non_empty_change_views(steward_tree, pull_request_files)

        unless non_empty_file_map.empty?
          output[github_username] = non_empty_file_map
        end
      end

      output
    end

    def combine_stewards_tree_maps(left_steward_tree_map, right_steward_tree_map)
      combined = {}

      github_usernames = (left_steward_tree_map.keys + right_steward_tree_map.keys).uniq
      github_usernames.each do |github_username|
        left_steward_tree  = left_steward_tree_map[github_username]
        right_steward_tree = right_steward_tree_map[github_username]

        combined[github_username] = combine_steward_trees(left_steward_tree, right_steward_tree)
      end

      combined
    end

    def combine_steward_trees(left_steward_tree, right_steward_tree)
      if left_steward_tree.nil? || right_steward_tree.nil?
        return right_steward_tree.presence || left_steward_tree.presence
      end

      combined = {}

      all_stewards_file_paths = (left_steward_tree.keys + right_steward_tree.keys).uniq
      all_stewards_file_paths.each do |stewards_file_path|
        left_change_views  = left_steward_tree[stewards_file_path]
        right_change_views = right_steward_tree[stewards_file_path]

        left_change_views = left_change_views.first unless left_change_views.nil?
        right_change_views = right_change_views.first unless right_change_views.nil?

        # TODO - handle the case
        raise "Handle this case" if ! left_change_views.nil? && !right_change_views.nil?

        combined[stewards_file_path] = [left_change_views, right_change_views].reject(&:nil?)
      end

      combined
    end
  end
end
