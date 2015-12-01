module Ladle
  class StewardsFile
    attr_reader :stewards

    def initialize(stewards = [])
      @stewards = stewards
    end
  end
end
