require 'ladle/changed_files'
require 'ladle/exceptions'
require 'ladle/file_change'
require 'ladle/pull_request_info'

module Ladle
  class GithubRepositoryClient
    def initialize(repository)
      @repository = repository
      @client     = Octokit::Client.new(access_token: @repository.access_token)
    end

    def pull_request(pr_number)
      pr = @client.pull_request(@repository.name, pr_number)
      Ladle::PullRequestInfo.new(pr[:head][:sha], pr[:base][:sha])
    end

    def pull_request_files(pr_number)
      changed_files = Ladle::ChangedFiles.new

      @client.pull_request_files(@repository.name, pr_number).each do |file|
        file_change = Ladle::FileChange.new(
          status:    file[:status].to_sym,
          file:      file[:filename],
          additions: file[:additions],
          deletions: file[:deletions]
        )
        changed_files.add_file_change(file_change)
      end

      changed_files
    end

    def contents(path:, ref:)
      content = @client.contents(@repository.name, path: path, ref: ref)[:content]
      Base64.decode64(content)
    rescue Octokit::NotFound
      raise Ladle::RemoteFileNotFound
    end
  end
end
