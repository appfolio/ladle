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
        {
          status:    "added",
          filename:  'one.rb',
          additions: 1,
          deletions: 0,
          changes:   0
        },
        {
          status:    "modified",
          filename:  'sub/marine.rb',
          additions: 0,
          deletions: 0,
          changes:   1
        },
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

    expected_stewards_changeset = Ladle::StewardsFileChangeset.new('stewards.yml', [
                                                                   build(:file_change, status: :added, file: 'one.rb', additions: 1),
                                                                   build(:file_change, status: :modified, file: 'sub/marine.rb', changes: 1),
                                                                 ])

    expected_sub_stewards_changeset = Ladle::StewardsFileChangeset.new('sub/stewards.yml', [
                                                                           build(:file_change, status: :modified, file: 'sub/marine.rb', changes: 1),
                                                                         ])
    notifier = mock
    notifier.expects(:notify)
      .with({
              'xanderstrike'      => [
                expected_sub_stewards_changeset,
                expected_stewards_changeset
              ],
              'fadsfadsfadsfadsf' => [
                expected_sub_stewards_changeset
              ],
              'bob'               => [
                expected_stewards_changeset
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
          filename: 'stewards.yml',
          additions: 0,
          deletions: 1,
          changes:   0
        },
        {
          status:    "added",
          filename:  'one.rb',
          additions: 1,
          deletions: 0,
          changes:   0
        },
        {
          status: "modified",
          filename: 'sub/marine.rb',
          additions: 0,
          deletions: 0,
          changes:   1
        },
        {
          status: "modified",
          filename: 'sub/stewards.yml',
          additions: 0,
          deletions: 0,
          changes:   1
        },
        {
          status: "removed",
          filename: 'sub2/sandwich',
          additions: 0,
          deletions: 1,
          changes:   0
        },
        {
          status: "removed",
          filename: 'sub3/stewards.yml',
          additions: 0,
          deletions: 1,
          changes:   0
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

    expected_stewards_changeset = Ladle::StewardsFileChangeset.new('stewards.yml', [
                                                                   build(:file_change, status: :removed, file: 'stewards.yml', deletions: 1),
                                                                   build(:file_change, status: :added, file: 'one.rb', additions: 1),
                                                                   build(:file_change, status: :modified, file: 'sub/marine.rb', changes: 1),
                                                                   build(:file_change, status: :modified, file: 'sub/stewards.yml', changes: 1),
                                                                   build(:file_change, status: :removed, file: 'sub2/sandwich', deletions: 1),
                                                                   build(:file_change, status: :removed, file: 'sub3/stewards.yml', deletions: 1)
                                                                 ])

    expected_sub_stewards_changeset = Ladle::StewardsFileChangeset.new('sub/stewards.yml', [
                                                                           build(:file_change, status: :modified, file: 'sub/marine.rb', changes: 1),
                                                                           build(:file_change, status: :modified, file: 'sub/stewards.yml', changes: 1)
                                                                         ])

    expected_sub3_stewards_changeset = Ladle::StewardsFileChangeset.new('sub3/stewards.yml', [build(:file_change, status: :removed, file: 'sub3/stewards.yml', deletions: 1)])

    notifier = mock
    notifier.expects(:notify)
      .with({
              'xanderstrike'      => [
                expected_sub_stewards_changeset,
                expected_stewards_changeset,
                expected_sub3_stewards_changeset,
              ],
              'fadsfadsfadsfadsf' => [
                expected_sub_stewards_changeset
              ],
              'bob'               => [
                expected_stewards_changeset,
                expected_sub3_stewards_changeset
              ],
              'jeb'               => [
                expected_sub_stewards_changeset
              ],
              'hamburglar'        => [
                Ladle::StewardsFileChangeset.new('sub2/stewards.yml', [build(:file_change, status: :removed, file: 'sub2/sandwich', deletions: 1)])
              ],
            })

    Ladle::PullHandler.new(@pull_request, notifier).handle
  end

  test 'notify - stewards file not in changeset' do
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
          status:   'added',
          filename: 'goodbye/kitty/sianara.txt',
          additions: 1,
          deletions: 0,
          changes:   0
        },
        {
          status:    "added",
          filename:  'hello/kitty/what/che.txt',
          additions: 1,
          deletions: 0,
          changes:   0
        },
        {
          status:    "removed",
          filename: 'hello/kitty/what/is/stewards.yml',
          additions: 0,
          deletions: 1,
          changes:   0
        }
      ])

    client.expects(:contents)
      .with(@repository.name, path: 'goodbye/kitty/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    client.expects(:contents)
      .with(@repository.name, path: 'goodbye/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    client.expects(:contents)
      .with(@repository.name, path: 'hello/kitty/what/is/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    client.expects(:contents)
      .with(@repository.name, path: 'hello/kitty/what/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    client.expects(:contents)
      .with(@repository.name, path: 'hello/kitty/stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    stub_stewards_file_contents(client, <<-YAML, path: 'hello/stewards.yml', ref: 'branch_head')
      stewards:
        - xanderstrike
    YAML

    client.expects(:contents)
      .with(@repository.name, path: 'stewards.yml', ref: 'branch_head')
      .raises(Octokit::NotFound)

    stub_stewards_file_contents(client, <<-YAML, path: 'hello/kitty/what/is/stewards.yml', ref: 'parent_head')
      stewards:
        - xanderstrike
        - bleh
    YAML

    expected_stewards_changeset = Ladle::StewardsFileChangeset.new('hello/stewards.yml', [
                                                                                   build(:file_change, status: :added, file: 'hello/kitty/what/che.txt', additions: 1),
                                                                                   build(:file_change, status: :removed, file: 'hello/kitty/what/is/stewards.yml', deletions: 1),
                                                                                 ])

    expected_sub_stewards_changeset = Ladle::StewardsFileChangeset.new('hello/kitty/what/is/stewards.yml', [
                                                                                           build(:file_change, status: :removed, file: 'hello/kitty/what/is/stewards.yml', deletions: 1),
                                                                                         ])

    notifier = mock
    notifier.stubs(:id).returns(1)
    notifier.expects(:notify)
      .with({
              'xanderstrike' => [
                expected_stewards_changeset,
                expected_sub_stewards_changeset,
              ],
              'bleh'        => [
                expected_sub_stewards_changeset
              ],
            })

    Ladle::PullHandler.new(@pull_request, notifier).handle
  end

  test "collect_files" do
    registry = {
      'xanderstrike' => [
        Ladle::StewardsFileChangeset.new('stewards.yml', []),
        Ladle::StewardsFileChangeset.new('sub/stewards.yml', []),
        Ladle::StewardsFileChangeset.new('sub3/stewards.yml', [])
      ]
    }

    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, file: 'stewards.yml'))
    changed_files.add_file_change(build(:file_change, file: 'one.rb'))
    changed_files.add_file_change(build(:file_change, file: 'sub/marine.rb'))
    changed_files.add_file_change(build(:file_change, file: 'sub/stewards.yml'))
    changed_files.add_file_change(build(:file_change, file: 'sub2/sandwich'))
    changed_files.add_file_change(build(:file_change, file: 'sub3/stewards.yml'))

    handler = Ladle::PullHandler.new(@pull_request, mock('notifier'))
    handler.send(:collect_files, registry, changed_files)

    expected_changeset = Ladle::StewardsFileChangeset.new('stewards.yml',
                                          [
                                            build(:file_change, file: 'stewards.yml'),
                                            build(:file_change, file: 'one.rb'),
                                            build(:file_change, file: 'sub/marine.rb'),
                                            build(:file_change, file: 'sub/stewards.yml'),
                                            build(:file_change, file: 'sub2/sandwich'),
                                            build(:file_change, file: 'sub3/stewards.yml')
                                          ]
    )

    assert_equal expected_changeset, registry['xanderstrike'].first
  end

  private

  def stub_stewards_file_contents(client, contents, path:, ref:)
    client.expects(:contents)
      .with(@repository.name, path: path, ref: ref)
      .returns(content: Base64.encode64(contents))
  end
end
