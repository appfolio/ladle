module Ladle
  class StewardChangesView
    attr_reader :stewards_file, :file_filter, :changes

    def initialize(stewards_file, file_filter, changes = nil)
      @file_filter   = file_filter
      @stewards_file = Pathname.new(stewards_file)
      @changes       = changes || []
    end

    def add_file_changes(file_changes)
      @changes.concat(file_changes)
    end

    def ==(other)
      @stewards_file.to_s == other.stewards_file.to_s &&
        @file_filter == other.file_filter &&
        @changes.to_set == other.changes.to_set
    end

    def hash
      [@stewards_file, @file_filter, @changes].hash
    end

    alias eql? ==
  end
end
