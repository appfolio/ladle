module Ladle
  class ChangesView
    include Enumerable

    RulesChanges = Struct.new(:rules, :changes)

    def initialize
      @paths = {}
    end

    def empty?
      @paths.values.all?(&:empty?)
    end

    def each
      sorted_paths = @paths.keys.sort
      sorted_paths.each do |path_key|
        rules_and_changes_list = @paths[path_key]

        rules_and_changes_list.each do |rules_and_changes|
          yield rules_and_changes.rules, rules_and_changes.changes
        end
      end
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
end
