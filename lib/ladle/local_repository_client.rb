require 'rugged'

require 'ladle/changed_files'
require 'ladle/exceptions'
require 'ladle/file_change'
require 'ladle/pull_request_info'

module Ladle
  class LocalRepositoryClient
    def initialize(path, base_ref:, head_ref:)
      @repo     = Rugged::Repository.new(path)
      @base_ref = base_ref
      @head_ref = head_ref
    end

    def pull_request(pr_number)
      Ladle::PullRequestInfo.new(@head_ref, @base_ref)
    end

    def pull_request_files(pr_number)
      @files ||= begin
        changed_files = Ladle::ChangedFiles.new

        commit = @repo.lookup(@base_ref)
        diff   = commit.diff(@head_ref)
        diff.deltas.each do |delta|
          file_change = Ladle::FileChange.new(
            status:    map_status(delta.status),
            file:      delta.new_file[:path],
            additions: 1,
            deletions: 0
          )

          changed_files = changed_files.add_file_change(file_change)
        end

        changed_files
      end
    end

    def contents(path:, ref:)
      commit = @repo.lookup(ref)

      blob_oid = nil
      commit.tree.walk_blobs do |root, entry|
        if File.join(root, entry[:name]) == path
          blob_oid = entry[:oid]
        end
      end

      unless blob_oid
        raise Ladle::RemoteFileNotFound, path
      end

      @repo.lookup(blob_oid).content
    end

    private

    def map_status(status)
      case status
      when :deleted then :removed
      when :added, :modified then status
      else
        raise "No support for status #{status.inspect}"
      end
    end
  end
end
