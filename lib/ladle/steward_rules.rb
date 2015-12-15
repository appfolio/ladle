require 'ladle/file_filter'

module Ladle
  class StewardRules
    attr_reader :ref, :stewards_file, :file_filter

    def initialize(ref:, stewards_file:, file_filter: nil)
      @ref           = ref
      @file_filter   = file_filter || FileFilter.new
      @stewards_file = Pathname.new(stewards_file)
    end

    def select_matching_file_changes(file_changes)
      file_changes.select do |file_change|
        @file_filter.include?(file_change.file.relative_path_from(@stewards_file.dirname))
      end
    end

    def ==(other)
      @ref == other.ref &&
        @stewards_file == other.stewards_file &&
        @file_filter == other.file_filter
    end

    def hash
      [@ref, @stewards_file, @file_filter].hash
    end

    alias eql? ==
  end
end
