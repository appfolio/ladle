require 'ladle/pull_request_info'
require 'ladle/exceptions'

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
      @client.pull_request_files(@repository.name, pr_number)
    end

    def contents(path:, ref:)
      content = @client.contents(@repository.name, path: path, ref: ref)[:content]
      Base64.decode64(content)
    rescue Octokit::NotFound
      raise Ladle::RemoteFileNotFound
    end
  end
end
