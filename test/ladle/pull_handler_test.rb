require 'test_helper'
require 'ladle/pull_handler'

class PullHandlerTest < ActiveSupport::TestCase
  setup do
    user = create(:user)
    @repository = Repository.create!(name: 'xanderstrike/test', webhook_secret: 'whatever', access_via: user)
    @pull_request = create(:pull_request, repository: @repository, number: 30, html_url: 'www.test.com')
  end

  test 'does nothing when there are not stewards' do
    client = Octokit::Client.any_instance
    client.expects(:pull_request).with(@repository.name, @pull_request.number).returns(
      {
        head: {
          sha: 'branch_head'
        },
        base: {
          sha: 'parent_head'
        }
      })

    client.expects(:pull_request_files).with(@repository.name, @pull_request.number).returns(
      [
        {status: "new", filename: 'one.rb'},
        {status: "modified", filename: 'sub/marine.rb'},
      ])

    client.expects(:contents).with(@repository.name, path: '/sub/stewards.yml', ref: 'branch_head').raises(Octokit::NotFound)
    client.expects(:contents).with(@repository.name, path: '/stewards.yml', ref: 'branch_head').raises(Octokit::NotFound)

    logger_mock = mock
    logger_mock.expects(:info).with('No stewards found. Doing nothing.')
    Rails.stubs(:logger).returns(logger_mock)

    Ladle::PullHandler.new(@pull_request, mock('notifier')).handle
  end

  test 'notifies stewards' do
    client = Octokit::Client.any_instance
    client.expects(:pull_request).with(@repository.name, @pull_request.number).returns(
      {
        head: {
          sha: 'branch_head'
        },
        base: {
          sha: 'parent_head'
        }
      })

    client.expects(:pull_request_files).with(@repository.name, @pull_request.number).returns(
      [
        {status: "new", filename: 'one.rb'},
        {status: "modified", filename: 'sub/marine.rb'},
      ])

    stub_stewards_file_contents(client, <<-YAML, path: '/sub/stewards.yml', ref: 'branch_head')
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML

    stub_stewards_file_contents(client, <<-YAML, path: '/stewards.yml', ref: 'branch_head')
      stewards:
        - xanderstrike
        - bob
    YAML

    notifier = mock
    notifier.expects(:notify)
      .with({
              'xanderstrike'      => ['/sub/stewards.yml', '/stewards.yml'],
              'fadsfadsfadsfadsf' => ['/sub/stewards.yml'],
              'bob'               => ['/stewards.yml']
            })

    Ladle::PullHandler.new(@pull_request, notifier).handle
  end

  test 'notifies old stewards' do
    client = Octokit::Client.any_instance
    client.expects(:pull_request).with(@repository.name, @pull_request.number).returns(
      {
        head: {
          sha: 'branch_head'
        },
        base: {
          sha: 'parent_head'
        }
      })

    client.expects(:pull_request_files).with(@repository.name, @pull_request.number).returns(
      [
        {
          status: 'removed',
          filename: 'stewards.yml'
        },
        {
          status: "new",
          filename: 'one.rb'
        },
        {
          status: "modified",
          filename: 'sub/marine.rb'
        },
        {
          status: "modified",
          filename: 'sub/stewards.yml'
        },
        {
          status: "removed",
          filename: 'sub2/sandwich'
        },
        {
          status: "removed",
          filename: 'sub3/stewards.yml'
        },
      ])

    client.expects(:contents)
      .with(@repository.name, path: '/sub3/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    stub_stewards_file_contents(client, <<-YAML, path: '/sub2/stewards.yml', ref: 'branch_head')
      stewards:
        - hamburglar
    YAML

    stub_stewards_file_contents(client, <<-YAML, path: '/sub/stewards.yml', ref: 'branch_head')
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML

    client.expects(:contents)
      .with(@repository.name, path: '/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    stub_stewards_file_contents(client, <<-YAML, path: '/stewards.yml', ref: 'parent_head')
      stewards:
        - xanderstrike
        - bob
    YAML

    stub_stewards_file_contents(client, <<-YAML, path: '/sub/stewards.yml', ref: 'parent_head')
      stewards:
        - jeb
    YAML

    stub_stewards_file_contents(client, <<-YAML, path: '/sub3/stewards.yml', ref: 'parent_head')
      stewards:
        - xanderstrike
        - bob
    YAML


    notifier = mock
    notifier.expects(:notify)
      .with({
              'xanderstrike'      => ['/sub/stewards.yml', '/stewards.yml', '/sub3/stewards.yml'],
              'fadsfadsfadsfadsf' => ['/sub/stewards.yml'],
              'bob'               => ['/stewards.yml', '/sub3/stewards.yml'],
              'jeb'               => ['/sub/stewards.yml'],
              'hamburglar'        => ['/sub2/stewards.yml']
            })

    Ladle::PullHandler.new(@pull_request, notifier).handle
  end

  test "directories_in_file_paths" do
    expected_directories = [
      "/some/really/deep",
      "/some/really",
      "/some",
      "/other",
      "/",
    ]

    handler     = Ladle::PullHandler.new(@pull_request, mock('notifier'))
    directories = handler.send(:directories_in_file_paths,
                               [
                                 "some/really/deep/file.rb",
                                 "other/file.rb",
                               ])

    assert_equal expected_directories, directories
  end

  private

  def stub_stewards_file_contents(client, contents, path:, ref:)
    client.expects(:contents)
      .with(@repository.name, path: path, ref: ref)
      .returns(content: Base64.encode64(contents))
  end
end
