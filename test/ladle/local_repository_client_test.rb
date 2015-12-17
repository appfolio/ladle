require 'test_helper'

require 'ladle/local_repository_client'
require 'ladle/pull_handler'

class LocalRepositoryClientTest < ActiveSupport::TestCase

  setup do
    @repository = create(:repository)
    @client     = Ladle::LocalRepositoryClient.new(Rails.root.to_s, base_ref: 'base_head', head_ref: 'branch_head')
  end

  test 'pull_request' do
    assert_equal Ladle::PullRequestInfo.new('branch_head', 'base_head'), @client.pull_request(12)
  end

  test "pull_request_files" do
    deltas = [
      mock(status: :added, new_file: {path: "one.rb"}),
      mock(status: :modified, new_file: {path: "sub/marine.rb"}),
    ]
    commit = mock
    commit.expects(:diff).with('branch_head').returns(mock(deltas: deltas))

    rugged_client = Rugged::Repository.any_instance
    rugged_client.expects(:lookup).with('base_head').returns(commit)

    expected = Ladle::ChangedFiles.new
    expected.add_file_change(build(:file_change, status: :added, file: 'one.rb'))
    expected.add_file_change(build(:file_change, status: :modified, file: 'sub/marine.rb'))

    assert_equal expected, @client.pull_request_files(12)

    # run again to verify memoization
    assert_equal expected, @client.pull_request_files(12)
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

  test "map_status" do
    assert_equal :removed, @client.send(:map_status, :deleted)
    assert_equal :added, @client.send(:map_status, :added)
    assert_equal :modified, @client.send(:map_status, :modified)
    raised = assert_raise RuntimeError do
      @client.send(:map_status, :what)
    end

    assert_equal "No support for status :what", raised.message
  end

  test "works with PullHandler" do
    handler_state = states('handler_state').starts_as('finding_files')

    deltas = [
      mock(status: :added, new_file: {path: "one.rb"}),
      mock(status: :modified, new_file: {path: "sub/marine.rb"}),
    ]

    commit = mock

    rugged_client = Rugged::Repository.any_instance
    rugged_client.expects(:lookup).with("base_head").when(handler_state.is('finding_files')).returns(commit)

    commit.expects(:diff).with('branch_head').returns(mock(deltas: deltas)).when(handler_state.is('finding_files')).then(handler_state.is('finding_content'))

    content = <<-YAML
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML

    tree = mock
    tree.expects(:walk_blobs).twice.multiple_yields(["",{name: "some_file.bleh"}], ["sub", {name: "stewards.yml", oid: "object_id"}])

    content_sequence = sequence('content')
    rugged_client.expects(:lookup).with("base_head").when(handler_state.is('finding_content')).in_sequence(content_sequence).returns(mock('commit', tree: tree))
    rugged_client.expects(:lookup).with("base_head").when(handler_state.is('finding_content')).in_sequence(content_sequence).returns(mock('commit', tree: tree))
    rugged_client.expects(:lookup).with('object_id').returns(mock(content: content))

    notifier = mock
    notifier.expects(:notify)

    handler = Ladle::PullHandler.new(@client, notifier)

    pull_request = create(:pull_request, repository: @repository)
    handler.handle(pull_request)
  end
end
