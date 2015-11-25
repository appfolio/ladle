module Ladle
  class StewardConfig
    attr_reader :github_username, :include_patterns, :exclude_patterns

    def initialize(github_username:, include_patterns: nil, exclude_patterns: nil)
      @github_username = github_username
      @include_patterns = Array.wrap(include_patterns || [])
      @exclude_patterns = Array.wrap(exclude_patterns || [])
    end

    def ==(other)
      @github_username == other.github_username &&
        @include_patterns == other.include_patterns &&
        @exclude_patterns == other.exclude_patterns
    end

    def hash
      [@github_username, @include_patterns, @exclude_patterns].hash
    end

    alias eql? ==
  end
end
