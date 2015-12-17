require 'ladle/stewards_file_parser'
require 'ladle/steward_rules'
require 'ladle/steward_tree'

module Ladle
  class PullHandler
    def initialize(client, notifier)
      @client = client
      @notifier = notifier
    end

    def handle(pull_request)
      pr_info = @client.pull_request(pull_request.number)

      pr_files = @client.pull_request_files(pull_request.number)

      stewards_trees = collect_stewards_rules(pr_info, pr_files)

      stewards_registry = collect_changes(stewards_trees, pr_files)

      if stewards_registry.empty?
        Rails.logger.info('No stewards found. Doing nothing.')
      else
        Rails.logger.info("Found #{stewards_registry.size} stewards. Notifying.")
        @notifier.notify(stewards_registry)
      end
    end

    private

    def collect_stewards_rules(pr_info, pr_files)
      rules = {}

      pr_files.directories.each do |directory|
        register_stewards(rules, directory.join('stewards.yml'), pr_info.base_sha)
      end

      pr_files.modified_stewards_files.each do |stewards_file_path|
        register_stewards(rules, stewards_file_path, pr_info.head_sha)
      end

      rules
    end

    def register_stewards(stewards_rules_map, stewards_file_path, sha)
      contents = @client.contents(path: stewards_file_path.to_s, ref: sha)
      stewards_file = StewardsFileParser.parse(contents)

      stewards_file.stewards.each do |steward_config|
        rules = Ladle::StewardRules.new(ref:           sha,
                                        stewards_file: stewards_file_path,
                                        file_filter:   steward_config.file_filter)

        stewards_rules_map[steward_config.github_username] ||= StewardTree.new
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
          output[github_username] = changes_view
        end
      end

      output
    end
  end
end
