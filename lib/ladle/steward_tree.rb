require 'ladle/changes_view'

module Ladle
  class StewardTree

    def initialize(rules = nil)
      @rules = rules || []
    end

    def add_rules(*rules)
      StewardTree.new(@rules + rules)
    end

    def changes(pull_request_files)
      changes_view = ChangesView.new

      @rules.each do |rules|
        file_changes = pull_request_files.file_changes_in(rules.stewards_file.dirname)
        file_changes = rules.select_matching_file_changes(file_changes)

        unless file_changes.empty?
          changes_view = changes_view.add_changes(rules, file_changes)
        end
      end

      changes_view
    end
  end
end
