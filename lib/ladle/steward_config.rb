require 'ladle/file_filter'

module Ladle
  class StewardConfig
    attr_reader :github_username, :file_filter

    def initialize(github_username:, include_patterns: nil, exclude_patterns: nil)
      @github_username = github_username
      @file_filter     = FileFilter.new(include_patterns: include_patterns, exclude_patterns: exclude_patterns)
    end

    def ==(other)
      @github_username == other.github_username &&
        @file_filter == other.file_filter
    end

    def hash
      [@github_username, @file_filter].hash
    end

    alias eql? ==
  end
end
