module Ladle
  class ChangesView
    include Enumerable

    RulesChanges = Struct.new(:rules, :changes)

    def initialize(*rules_and_changes)
      @paths = {}

      rules_and_changes.each do |rules:, changes:|
        add_changes_to(rules, changes)
      end
    end

    def empty?
      @paths.values.all?(&:empty?)
    end

    def ==(other)
      @paths == other.paths
    end

    alias eql? ==

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
      new_instance = self.dup
      new_instance.add_changes_to(rules, changes)
      new_instance
    end

    protected

    attr_reader :paths

    def add_changes_to(rules, changes)
      @paths[rules.stewards_file.to_s] ||= []

      rules_and_changes_collection = @paths[rules.stewards_file.to_s]

      changes_already_exist = rules_and_changes_collection.any? do |rules_changes|
        rules_changes.changes == changes
      end

      unless changes_already_exist
        rules_and_changes_collection << RulesChanges.new(rules, changes)
      end
    end

    private

    def initialize_copy(other)
      @paths = other.paths.dup
    end
  end
end
