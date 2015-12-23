require 'test_helper'

require 'ladle/github_repository_client'
require 'ladle/pull_handler'

class GithubRepositoryClientTest < ActiveSupport::TestCase

  setup do
    @repository = create(:repository)
    @client     = Ladle::GithubRepositoryClient.new(@repository)
  end

  test 'pull_request' do
    octokit_client = Octokit::Client.any_instance
    octokit_client.expects(:pull_request).with(@repository.name, 12).returns({
                                                                               head: {
                                                                                 sha: 'branch_head'
                                                                               },
                                                                               base: {
                                                                                 sha: 'base_head'
                                                                               }
                                                                             })

    assert_equal Ladle::PullRequestInfo.new('branch_head', 'base_head'), @client.pull_request(12)
  end

  test "pull_request_files" do
    octokit_client = Octokit::Client.any_instance
    octokit_client.expects(:pull_request_files).with(@repository.name, 12).returns([
                                                                                     {status: "added", filename: 'one.rb'},
                                                                                     {status: "modified", filename: 'sub/marine.rb'},
                                                                                   ])

    expected = Ladle::ChangedFiles.new(
      build(:file_change, status: :added, file: 'one.rb'),
      build(:file_change, status: :modified, file: 'sub/marine.rb')
    )

    assert_equal expected, @client.pull_request_files(12)
  end

  test "contents" do
    expected_result = <<-YAML
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML

    octokit_client = Octokit::Client.any_instance

    stub_stewards_file_contents(octokit_client, expected_result, path: 'sub/stewards.yml', ref: 'branch_head')

    assert_equal expected_result, @client.contents(path: 'sub/stewards.yml', ref: 'branch_head')
  end

  test "contents - not found" do
    octokit_client = Octokit::Client.any_instance
    octokit_client.expects(:contents)
      .with(@repository.name, path: 'sub/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    raised = assert_raises Ladle::RemoteFileNotFound do
      @client.contents(path: 'sub/stewards.yml', ref: 'branch_head')
    end

    assert_equal Octokit::NotFound, raised.cause.class
  end

  test "works with PullHandler" do
    expected_result = {
      head: {
        sha: 'branch_head'
      },
      base: {
        sha: 'base_head'
      }
    }

    octokit_client = Octokit::Client.any_instance
    octokit_client.expects(:pull_request).with(@repository.name, 12).returns(expected_result)

    handler_state = states('handler_state').starts_as('finding_files')

    expected_result = [
      {status: "added", filename: 'one.rb'},
      {status: "modified", filename: 'sub/marine.rb'},
    ]

    octokit_client.expects(:pull_request_files).with(@repository.name, 12).returns(expected_result)

    expected_result = <<-YAML
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML

    stub_stewards_file_contents(octokit_client, expected_result, path: 'sub/stewards.yml', ref: 'base_head')

    octokit_client.expects(:contents)
      .with(@repository.name, path: 'stewards.yml', ref: 'base_head')
      .raises(Octokit::NotFound)

    notifier = mock
    notifier.expects(:notify)

    handler = Ladle::PullHandler.new(@client, notifier)

    pull_request = create(:pull_request, repository: @repository, number: 12)
    handler.handle(pull_request)
  end

  private

  def stub_stewards_file_contents(octokit_client, contents, path:, ref:)
    octokit_client.expects(:contents)
      .with(@repository.name, path: path, ref: ref)
      .returns(content: Base64.encode64(contents))
  end
end
