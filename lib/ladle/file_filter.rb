module Ladle
  class FileFilter
    def initialize(include_patterns: nil, exclude_patterns: nil)
      @include_patterns = Array.wrap(include_patterns || [])
      @exclude_patterns = Array.wrap(exclude_patterns || [])
    end

    def ==(other)
      @include_patterns == other.include_patterns &&
        @exclude_patterns == other.exclude_patterns
    end

    def hash
      [@include_patterns, @exclude_patterns].hash
    end

    alias eql? ==

    protected

    attr_reader :include_patterns, :exclude_patterns
  end

end
