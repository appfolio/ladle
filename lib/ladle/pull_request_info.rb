module Ladle
  class PullRequestInfo
    attr_reader :head_sha, :base_sha

    def initialize(head_sha, base_sha)
      @head_sha = head_sha
      @base_sha = base_sha
    end

    def ==(other)
      @head_sha == other.head_sha &&
        @base_sha == other.base_sha
    end

    alias eql? ==
  end
end
