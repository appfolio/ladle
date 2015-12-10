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

    def include?(file_pathname)
      matches_include = @include_patterns.empty? || @include_patterns.any? do |include_pattern|
        file_pathname.fnmatch?(include_pattern)
      end

      matches_exclude = @exclude_patterns.any? do |exclude_pattern|
        file_pathname.fnmatch?(exclude_pattern)
      end

      matches_include && ! matches_exclude
    end

    def inspect
      {
        include: @include_patterns,
        exclude: @exclude_patterns,
      }.inspect
    end

    protected

    attr_reader :include_patterns, :exclude_patterns
  end

end
