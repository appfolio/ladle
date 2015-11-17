module Ladle
  class StewardsFileChangeset
    attr_reader :stewards_file, :changes

    def initialize(stewards_file, changes = nil)
      @stewards_file = Pathname.new(stewards_file)
      @changes       = changes || []
    end

    def ==(other)
      @stewards_file.to_s == other.stewards_file.to_s && @changes.to_set == other.changes.to_set
    end

    def hash
      [@stewards_file, @changes].hash
    end

    alias eql? ==
  end
end
