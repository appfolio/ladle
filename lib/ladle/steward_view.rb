module Ladle
  class StewardView
    attr_reader :changesets

    def initialize(changesets = [])
      @changesets = changesets
    end

    def add_changeset(changeset)
      @changesets << changeset
    end

    def ==(other)
      @changesets == other.changesets
    end

    alias eql? ==

    def hash
      @changesets.hash
    end
  end
end

