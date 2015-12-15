require 'ladle/file_filter'

module Ladle
  class StewardChangesView
    attr_reader :ref, :stewards_file, :file_filter, :changes

    def initialize(ref:, stewards_file:, file_filter: nil, changes: nil)
      @ref           = ref
      @file_filter   = file_filter || FileFilter.new
      @stewards_file = Pathname.new(stewards_file)
      @changes       = changes || []
    end

    def ==(other)
      @ref == other.ref &&
        @stewards_file.to_s == other.stewards_file.to_s &&
        @file_filter == other.file_filter &&
        @changes.to_set == other.changes.to_set
    end

    def hash
      [@ref, @stewards_file, @file_filter, @changes].hash
    end

    alias eql? ==
  end
end
