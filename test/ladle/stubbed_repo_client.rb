module Ladle
  class StubbedRepoClient
    class TreeDefinition
      def initialize(ref, repo)
        @ref = ref
        @repo = repo
      end

      def file(path, contents)
        @repo.add_stewards_file(ref: @ref, path: path, contents: contents)
      end
    end

    def initialize(pull_request_number, pull_request_info, changed_files)
      @pull_request_number = pull_request_number
      @pull_request_info   = pull_request_info
      @changed_files       = changed_files

      @repo                              = {}
      @repo[@pull_request_info.head_sha] = {}
      @repo[@pull_request_info.base_sha] = {}
    end

    def add_stewards_file(ref:, path:, contents:)
      repo_at_ref = @repo[ref]
      raise "Ref #{ref.inspect} not in repo" unless repo_at_ref

      repo_at_ref[path] = contents
    end

    def define_tree(ref)
      yield TreeDefinition.new(ref, self)
    end

    def contents(path:, ref:)
      repo_at_ref = @repo[ref]
      raise "Ref #{ref.inspect} not in repo" unless repo_at_ref

      if repo_at_ref[path]
        repo_at_ref[path]
      else
        raise Ladle::RemoteFileNotFound, "#{path} not found"
      end
    end

    def pull_request(pr_number)
      raise "Unexpected PR ##{pr_number}" unless pr_number == @pull_request_number
      @pull_request_info
    end

    def pull_request_files(pr_number)
      raise "Unexpected PR ##{pr_number}" unless pr_number == @pull_request_number
      @changed_files
    end
  end
end
