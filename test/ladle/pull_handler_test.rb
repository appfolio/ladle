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
        {status: "added", filename: 'one.rb'},
        {status: "modified", filename: 'sub/marine.rb'},
      ])

    client.expects(:contents).with(@repository.name, path: 'sub/stewards.yml', ref: 'branch_head').raises(Octokit::NotFound)
    client.expects(:contents).with(@repository.name, path: 'stewards.yml', ref: 'branch_head').raises(Octokit::NotFound)

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
        {status: "added", filename: 'one.rb'},
        {status: "modified", filename: 'sub/marine.rb'},
      ])

    stub_stewards_file_contents(client, <<-YAML, path: 'sub/stewards.yml', ref: 'branch_head')
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML

    stub_stewards_file_contents(client, <<-YAML, path: 'stewards.yml', ref: 'branch_head')
      stewards:
        - xanderstrike
        - bob
    YAML

    notifier = mock
    notifier.expects(:notify)
      .with({
              'xanderstrike'      => [
                create_changeset('sub/stewards.yml', [:modified, 'sub/marine.rb']),
                create_changeset('stewards.yml',     [:added, 'one.rb'], [:modified, 'sub/marine.rb']),
              ],
              'fadsfadsfadsfadsf' => [
                create_changeset('sub/stewards.yml', [:modified, 'sub/marine.rb'])
              ],
              'bob'               => [
                create_changeset('stewards.yml',     [:added, 'one.rb'], [:modified, 'sub/marine.rb']),
              ]
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
          status: "added",
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
      .with(@repository.name, path: 'sub3/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    stub_stewards_file_contents(client, <<-YAML, path: 'sub2/stewards.yml', ref: 'branch_head')
      stewards:
        - hamburglar
    YAML

    stub_stewards_file_contents(client, <<-YAML, path: 'sub/stewards.yml', ref: 'branch_head')
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML

    client.expects(:contents)
      .with(@repository.name, path: 'stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    stub_stewards_file_contents(client, <<-YAML, path: 'stewards.yml', ref: 'parent_head')
      stewards:
        - xanderstrike
        - bob
    YAML

    stub_stewards_file_contents(client, <<-YAML, path: 'sub/stewards.yml', ref: 'parent_head')
      stewards:
        - jeb
    YAML

    stub_stewards_file_contents(client, <<-YAML, path: 'sub3/stewards.yml', ref: 'parent_head')
      stewards:
        - xanderstrike
        - bob
    YAML

    notifier = mock
    notifier.expects(:notify)
      .with({
              'xanderstrike'      => [
                create_changeset('sub/stewards.yml', [:modified, 'sub/marine.rb'], [:modified, 'sub/stewards.yml']),
                create_changeset('stewards.yml',
                                 [:removed, 'stewards.yml'],
                                 [:added, 'one.rb'],
                                 [:modified, 'sub/marine.rb'],
                                 [:modified, 'sub/stewards.yml'],
                                 [:removed, 'sub2/sandwich'],
                                 [:removed, 'sub3/stewards.yml']
                ),
                create_changeset('sub3/stewards.yml', [:removed, 'sub3/stewards.yml']),
              ],
              'fadsfadsfadsfadsf' => [
                create_changeset('sub/stewards.yml', [:modified, 'sub/marine.rb'], [:modified, 'sub/stewards.yml']),
              ],
              'bob'               => [
                create_changeset('stewards.yml',
                                 [:removed, 'stewards.yml'],
                                 [:added, 'one.rb'],
                                 [:modified, 'sub/marine.rb'],
                                 [:modified, 'sub/stewards.yml'],
                                 [:removed, 'sub2/sandwich'],
                                 [:removed, 'sub3/stewards.yml']
                ),
                create_changeset('sub3/stewards.yml', [:removed, 'sub3/stewards.yml'])
              ],
              'jeb'               => [
                create_changeset('sub/stewards.yml', [:modified, 'sub/marine.rb'], [:modified, 'sub/stewards.yml']),
              ],
              'hamburglar'        => [
                create_changeset('sub2/stewards.yml', [:removed, 'sub2/sandwich'],)
              ],
            })

    Ladle::PullHandler.new(@pull_request, notifier).handle
  end

  test "collect_files" do
    registry = {
      'xanderstrike' => [
        create_changeset('stewards.yml'),
        create_changeset('sub/stewards.yml'),
        create_changeset('sub3/stewards.yml')
      ]
    }

    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(Ladle::FileChange.new(:removed, 'stewards.yml'))
    changed_files.add_file_change(Ladle::FileChange.new(:added, 'one.rb'))
    changed_files.add_file_change(Ladle::FileChange.new(:modified, 'sub/marine.rb'))
    changed_files.add_file_change(Ladle::FileChange.new(:modified, 'sub/stewards.yml'))
    changed_files.add_file_change(Ladle::FileChange.new(:removed, 'sub2/sandwich'))
    changed_files.add_file_change(Ladle::FileChange.new(:removed, 'sub3/stewards.yml'))

    handler = Ladle::PullHandler.new(@pull_request, mock('notifier'))
    handler.send(:collect_files, registry, changed_files)

    expected_changeset = create_changeset('stewards.yml',
                                          [:removed, 'stewards.yml'],
                                          [:added, 'one.rb'],
                                          [:modified, 'sub/marine.rb'],
                                          [:modified, 'sub/stewards.yml'],
                                          [:removed, 'sub2/sandwich'],
                                          [:removed, 'sub3/stewards.yml']
    )

    assert_equal expected_changeset, registry['xanderstrike'].first
  end

  private

  def stub_stewards_file_contents(client, contents, path:, ref:)
    client.expects(:contents)
      .with(@repository.name, path: path, ref: ref)
      .returns(content: Base64.encode64(contents))
  end

  def create_changeset(stewards_file, *change_pairs)
    Ladle::StewardsFileChangeset.new(stewards_file,
                                     change_pairs.map { |status, file|
                                       Ladle::FileChange.new(status, Pathname.new(file))
                                     })
  end
end
