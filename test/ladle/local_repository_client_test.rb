require 'test_helper'

require 'ladle/local_repository_client'

class LocalRepositoryClientTest < ActiveSupport::TestCase

  setup do
    @repository = create(:repository)
    @client     = Ladle::LocalRepositoryClient.new('test/test_repo', base_ref: 'parent_head', head_ref: 'branch_head')
  end

  test 'pull_request' do
    expected_result = {
      head: {
        sha: 'branch_head'
      },
      base: {
        sha: 'parent_head'
      }
    }

    assert_equal expected_result, @client.pull_request(12)
  end

  test "pull_request_files" do
    deltas = [
      mock(status: :added, new_file: {path: "one.rb"}),
      mock(status: :modified, new_file: {path: "sub/marine.rb"}),
    ]
    commit = mock
    commit.expects(:diff).with('parent_head').returns(mock(deltas: deltas))

    rugged_client = Rugged::Repository.any_instance
    rugged_client.expects(:lookup).with('branch_head').returns(commit)

    expected_result = [
      {status: "added", filename: 'one.rb', additions: 1, deletions: 0},
      {status: "modified", filename: 'sub/marine.rb', additions: 1, deletions: 0},
    ]

    assert_equal expected_result, @client.pull_request_files(12)

    # run again to verify memoization
    assert_equal expected_result, @client.pull_request_files(12)
  end

  test "contents" do
    expected_result = <<-YAML
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML

    tree = mock
    tree.expects(:walk_blobs).multiple_yields(["",{name: "some_file.bleh"}], ["sub", {name: "stewards.yml", oid: "object_id"}])

    rugged_client = Rugged::Repository.any_instance
    rugged_client.expects(:lookup).with('branch_head').returns(mock('commit', tree: tree))
    rugged_client.expects(:lookup).with('object_id').returns(mock(content: expected_result))

    assert_equal expected_result, @client.contents(path: 'sub/stewards.yml', ref: 'branch_head')
  end

  test "contents - not found" do
    tree = mock
    tree.expects(:walk_blobs).multiple_yields(["",{name: "some_file.bleh"}])

    rugged_client = Rugged::Repository.any_instance
    rugged_client.expects(:lookup).with('branch_head').returns(mock('commit', tree: tree))

    raised = assert_raises Ladle::RemoteFileNotFound do
      @client.contents(path: 'sub/stewards.yml', ref: 'branch_head')
    end

    assert_equal 'sub/stewards.yml', raised.message
  end

  
end
