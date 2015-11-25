module Ladle
  class StewardsFile
    attr_reader :stewards

    class Steward
      attr_reader :github_username, :include_patterns, :exclude_patterns

      def initialize(github_username:, include_patterns: nil, exclude_patterns: nil)
        @github_username = github_username
        @include_patterns = include_patterns || []
        @exclude_patterns = exclude_patterns || []
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

    def initialize(stewards = [])
      @stewards = stewards
    end

    def self.parse(contents)
      raise "Cannot parse empty file" if contents.blank?

      yaml_contents = YAML.load(contents)
      stewards = (yaml_contents["stewards"] || []).map do |config|
        github_username = config
        include_patterns = []
        exclude_patterns = []

        if config.is_a?(Hash)
          github_username = config["github_username"]
          include_patterns = config["include"]
          exclude_patterns = config["exclude"]
        end
        Steward.new(github_username: github_username, include_patterns: include_patterns, exclude_patterns: exclude_patterns)
      end

      new(stewards)
    end
  end
end
