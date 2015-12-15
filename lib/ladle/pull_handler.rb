require 'ladle/stewards_file_parser'
require 'ladle/steward_rules'

module Ladle
  class PullHandler
    def initialize(client, notifier)
      @client = client
      @notifier = notifier
    end

    def handle(pull_request)
      pr_info = @client.pull_request(pull_request.number)

      pr_files = @client.pull_request_files(pull_request.number)

      stewards_trees = collect_stewards_rules(pull_request, pr_info, pr_files)

      stewards_registry = collect_changes(stewards_trees, pr_files)

      if stewards_registry.empty?
        Rails.logger.info('No stewards found. Doing nothing.')
      else
        Rails.logger.info("Found #{stewards_registry.size} stewards. Notifying.")
        @notifier.notify(stewards_registry)
      end
    end

    private

    def collect_stewards_rules(pull_request, pr_info, pr_files)
      rules = {}

      pr_files.directories.each do |directory|
        register_stewards(rules, directory.join('stewards.yml'), pr_info.base_sha)
      end

      pr_files.modified_stewards_files.each do |stewards_file_path|
        register_stewards(rules, stewards_file_path, pr_info.head_sha)
      end

      rules
    end

    class ChangesView
      attr_reader :paths

      RulesChanges = Struct.new(:rules, :changes)

      def initialize
        @paths = {}
      end

      def empty?
        @paths.values.all?(&:empty?)
      end

      def add_changes(rules, changes)
        @paths[rules.stewards_file.to_s] ||= []

        add_changes_to(@paths[rules.stewards_file.to_s], rules, changes)
      end

      private

      def add_changes_to(rules_and_changes_collection, rules, changes)
        changes_already_exist = rules_and_changes_collection.any? do |rules_changes|
          rules_changes.changes == changes
        end

        unless changes_already_exist
          rules_and_changes_collection << RulesChanges.new(rules, changes)
        end
      end
    end

    class StewardTree
      attr_reader :github_username

      def initialize(github_username)
        @github_username = github_username
        @rules           = []
      end

      def add_rules(rules)
        @rules << rules
      end

      def changes(pull_request_files)
        changes_view = ChangesView.new

        @rules.each do |rules|
          file_changes = pull_request_files.file_changes_in(rules.stewards_file.dirname)
          file_changes = rules.select_matching_file_changes(file_changes)

          unless file_changes.empty?
            changes_view.add_changes(rules, file_changes)
          end
        end

        changes_view
      end
    end

    def register_stewards(stewards_rules_map, stewards_file_path, sha)
      contents = @client.contents(path: stewards_file_path.to_s, ref: sha)
      stewards_file = StewardsFileParser.parse(contents)

      stewards_file.stewards.each do |steward_config|
        rules = Ladle::StewardRules.new(ref:           sha,
                                        stewards_file: stewards_file_path,
                                        file_filter:   steward_config.file_filter)

        stewards_rules_map[steward_config.github_username] ||= StewardTree.new(steward_config.github_username)
        stewards_rules_map[steward_config.github_username].add_rules(rules)
      end
    rescue Ladle::RemoteFileNotFound
      # Ignore - stewards files don't have to exist
    rescue StewardsFileParser::ParsingError => e
      Rails.logger.error("Error parsing file #{stewards_file_path}: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    def collect_changes(stewards_trees, pull_request_files)
      output = {}

      stewards_trees.each do |github_username, steward_tree|
        changes_view = steward_tree.changes(pull_request_files)

        unless changes_view.empty?
          output[github_username] = map_to_old_stewards_tree_change_view(changes_view)
        end
      end

      output
    end

    def map_to_old_stewards_tree_change_view(changes_view)
      old_datastructure = {}
      changes_view.paths.each do |stewards_file_path, rules_with_changes_list|
        old_datastructure[stewards_file_path] = rules_with_changes_list.map do |rule_with_changes|
          Ladle::StewardChangesView.new(ref:           rule_with_changes.rules.ref,
                                        stewards_file: rule_with_changes.rules.stewards_file,
                                        file_filter:   rule_with_changes.rules.file_filter,
                                        changes:       rule_with_changes.changes)
        end
      end

      old_datastructure
    end
  end
end
