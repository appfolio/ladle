require 'ladle/steward_config'

module Ladle
  class StewardsFile
    class ParsingError < StandardError
    end

    attr_reader :stewards

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

        raise ParsingError, "Missing required key: github_username" if github_username.blank?

        StewardConfig.new(github_username: github_username, include_patterns: include_patterns, exclude_patterns: exclude_patterns)
      end

      new(stewards)
    end
  end
end
