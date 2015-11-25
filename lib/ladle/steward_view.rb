module Ladle
  class StewardView
    attr_reader :change_views

    def initialize(change_views = [])
      @change_views = change_views
    end

    def add_change_view(change_view)
      @change_views << change_view
    end

    def ==(other)
      @change_views == other.change_views
    end

    alias eql? ==

    def hash
      change_views.hash
    end
  end
end

