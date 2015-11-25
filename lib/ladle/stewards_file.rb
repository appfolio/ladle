module Ladle
  class StewardsFile
    attr_reader :stewards

    class Steward
      attr_reader :github_username

      def initialize(github_username)
        @github_username = github_username
      end
    end

    def initialize(stewards = [])
      @stewards = stewards
    end

    def self.parse(contents)
      stewards = YAML.load(contents)["stewards"].map do |steward_config|
        Steward.new(steward_config)
      end

      new(stewards)
    end
  end
end
