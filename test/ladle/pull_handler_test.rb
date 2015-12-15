require 'test_helper'

require 'ladle/pull_handler'
require 'ladle/pull_request_info'
require 'ladle/changed_files'
require 'ladle/file_filter'

require 'ladle/stubbed_repo_client'

require 'mocha_deep_hash'

class PullHandlerTest < ActiveSupport::TestCase
  setup do
    user = create(:user)
    @repository = Repository.create!(name: 'xanderstrike/test', webhook_secret: 'whatever', access_via: user)
    @pull_request = create(:pull_request, repository: @repository, number: 30, html_url: 'www.test.com')
  end

  test 'does nothing when there are not stewards' do
    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, status: :added, file: 'one.rb'))
    changed_files.add_file_change(build(:file_change, status: :modified, file: 'sub/marine.rb'))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    logger_mock = mock
    logger_mock.expects(:info).with('No stewards found. Doing nothing.')
    Rails.stubs(:logger).returns(logger_mock)

    Ladle::PullHandler.new(client, mock('notifier')).handle(@pull_request)
  end

  test 'notifies stewards' do
    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, status: :added, file: 'one.rb', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    client.define_tree('base_head') do |tree|

      tree.file('sub/stewards.yml', <<-YAML)
        stewards:
          - xanderstrike
          - fadsfadsfadsfadsf
      YAML

      tree.file('stewards.yml', <<-YAML)
        stewards:
          - github_username: bob
            include: "**.rb"
            exclude: "**.txt"
          - xanderstrike
      YAML
    end

    expected_stewards_changes_view = build(:steward_changes_view,
                                           ref: 'base_head',
                                           stewards_file: 'stewards.yml',
                                           changes:       [
                                                            build(:file_change, status: :added, file: 'one.rb', additions: 1),
                                                            build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
                                                          ])

    expected_sub_stewards_changes_view = build(:steward_changes_view,
                                               ref: 'base_head',
                                               stewards_file: 'sub/stewards.yml',
                                               changes:       [
                                                                build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
                                                              ])
    notifier = mock
    notifier.expects(:notify)
      .with(deep_hash({
              'xanderstrike'      => {
                'sub/stewards.yml' => [expected_sub_stewards_changes_view],
                'stewards.yml'     => [expected_stewards_changes_view]
              },
              'fadsfadsfadsfadsf' => {
                'sub/stewards.yml' => [expected_sub_stewards_changes_view]
              },
              'bob'               => {
                'stewards.yml' => [build(:steward_changes_view,
                                         ref: 'base_head',
                                         stewards_file: 'stewards.yml',
                                         file_filter:   Ladle::FileFilter.new(
                                           include_patterns: ["**.rb"],
                                           exclude_patterns: ["**.txt"]
                                         ),
                                         changes:       [
                                                          build(:file_change, status: :added, file: 'one.rb', additions: 1),
                                                          build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
                                                        ])
                ]
              }
            }))

    Ladle::PullHandler.new(client, notifier).handle(@pull_request)
  end

  test 'notifies steward from same file across branches' do
    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, status: :added, file: 'file1.txt', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :added, file: 'file2.txt', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :modified, file: 'stewards.yml', additions: 1))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    client.add_stewards_file(path: 'stewards.yml', ref: 'base_head', contents: <<-YAML)
      stewards:
        - github_username: someguy
          include: file1.txt
    YAML

    client.add_stewards_file(path: 'stewards.yml', ref: 'branch_head', contents: <<-YAML)
      stewards:
        - github_username: someguy
          include: file2.txt
    YAML

    base_changes = build(:steward_changes_view,
                         ref: 'base_head',
                         stewards_file: 'stewards.yml',
                         file_filter:   Ladle::FileFilter.new(
                           include_patterns: ["file1.txt"]
                         ),
                         changes:       [
                                          build(:file_change, status: :added, file: 'file1.txt', additions: 1)
                                        ])

    branch_changes = build(:steward_changes_view,
                           ref: 'branch_head',
                           stewards_file: 'stewards.yml',
                           file_filter:   Ladle::FileFilter.new(
                             include_patterns: ["file2.txt"]
                           ),
                           changes:       [
                                            build(:file_change, status: :added, file: 'file2.txt', additions: 1)
                                          ])

    notifier = mock
    notifier.expects(:notify)
      .with(deep_hash({
                        'someguy' => {
                          'stewards.yml' => [
                            base_changes,
                            branch_changes,
                          ],
                        }}))

    Ladle::PullHandler.new(client, notifier).handle(@pull_request)
  end

  test 'notifies steward from same file across branches - remove duplicates' do
    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, status: :added, file: 'file1.txt', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :added, file: 'file2.txt', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :modified, file: 'stewards.yml', additions: 1))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    client.add_stewards_file(path: 'stewards.yml', ref: 'base_head', contents: <<-YAML)
      stewards:
        - github_username: someguy
          include: file1.txt
    YAML

    client.add_stewards_file(path: 'stewards.yml', ref: 'branch_head', contents: <<-YAML)
      stewards:
        - github_username: someguy
          include: file1.*
    YAML

    changes = build(:steward_changes_view,
                    ref: 'base_head',
                    stewards_file: 'stewards.yml',
                    file_filter:   Ladle::FileFilter.new(
                      include_patterns: ["file1.txt"]
                    ),
                    changes:       [
                                     build(:file_change, status: :added, file: 'file1.txt', additions: 1)
                                   ])

    notifier = mock
    notifier.expects(:notify)
      .with(deep_hash({
                        'someguy' => {
                          'stewards.yml' => [changes],
                        }}))

    Ladle::PullHandler.new(client, notifier).handle(@pull_request)
  end

  test 'notifies old stewards' do
    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, status: :removed, file: 'stewards.yml', deletions: 1))
    changed_files.add_file_change(build(:file_change, status: :added, file: 'one.rb', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :modified, file: 'sub/stewards.yml', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :removed, file: 'sub2/sandwich', deletions: 1))
    changed_files.add_file_change(build(:file_change, status: :added, file: 'sub2/stewards.yml', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :removed, file: 'sub3/stewards.yml', deletions: 1))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    client.define_tree('base_head') do |tree|
      tree.file('sub3/stewards.yml', <<-YAML)
        stewards:
          - xanderstrike
          - bob
      YAML

      tree.file('sub/stewards.yml', <<-YAML)
        stewards:
          - jeb
      YAML

      tree.file('stewards.yml', <<-YAML)
        stewards:
          - xanderstrike
          - bob
      YAML
    end

    client.define_tree('branch_head') do |tree|
      tree.file('sub2/stewards.yml', <<-YAML)
        stewards:
          - hamburglar
      YAML

      tree.file('sub/stewards.yml', <<-YAML)
        stewards:
          - xanderstrike
          - fadsfadsfadsfadsf
      YAML
    end

    expected_stewards_changes_view = build(:steward_changes_view,
                                           ref: 'base_head',
                                           stewards_file: 'stewards.yml',
                                           changes:       [
                                                            build(:file_change, status: :removed, file: 'stewards.yml', deletions: 1),
                                                            build(:file_change, status: :added, file: 'one.rb', additions: 1),
                                                            build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1),
                                                            build(:file_change, status: :modified, file: 'sub/stewards.yml', additions: 1),
                                                            build(:file_change, status: :removed, file: 'sub2/sandwich', deletions: 1),
                                                            build(:file_change, status: :added, file: 'sub2/stewards.yml', additions: 1),
                                                            build(:file_change, status: :removed, file: 'sub3/stewards.yml', deletions: 1)
                                                          ])

    expected_sub_stewards_changes_view = build(:steward_changes_view,
                                               ref:           'branch_head',
                                               stewards_file: 'sub/stewards.yml',
                                               changes:       [
                                                                build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1),
                                                                build(:file_change, status: :modified, file: 'sub/stewards.yml', additions: 1)
                                                              ])

    expected_sub2_stewards_changes_view = build(:steward_changes_view,
                                                ref:           'branch_head',
                                                stewards_file: 'sub2/stewards.yml',
                                                changes:       [
                                                                 build(:file_change, status: :removed, file: 'sub2/sandwich', deletions: 1),
                                                                 build(:file_change, status: :added, file: 'sub2/stewards.yml', additions: 1)
                                                               ])

    expected_sub3_stewards_changes_view = build(:steward_changes_view,
                                                ref:           'base_head',
                                                stewards_file: 'sub3/stewards.yml',
                                                changes:       [
                                                                 build(:file_change, status: :removed, file: 'sub3/stewards.yml', deletions: 1)
                                                               ])

    notifier = mock
    notifier.expects(:notify)
      .with(deep_hash({
              'xanderstrike'      => {
                'sub/stewards.yml'  => [expected_sub_stewards_changes_view],
                'stewards.yml'      => [expected_stewards_changes_view],
                'sub3/stewards.yml' => [expected_sub3_stewards_changes_view],
              },
              'fadsfadsfadsfadsf' => {
                'sub/stewards.yml' => [expected_sub_stewards_changes_view]
              },
              'bob'               => {
                'stewards.yml'      => [expected_stewards_changes_view],
                'sub3/stewards.yml' => [expected_sub3_stewards_changes_view]
              },
              'jeb'               => {
                'sub/stewards.yml' => [build(:steward_changes_view,
                                             ref:           'base_head',
                                             stewards_file: 'sub/stewards.yml',
                                             changes:       [
                                                              build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1),
                                                              build(:file_change, status: :modified, file: 'sub/stewards.yml', additions: 1)
                                                            ])]
              },
              'hamburglar'        => {
                'sub2/stewards.yml' => [expected_sub2_stewards_changes_view]
              },
            }))

    Ladle::PullHandler.new(client, notifier).handle(@pull_request)
  end

  test 'notify - stewards file not in changes_view' do
    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, status: :added, file: 'goodbye/kitty/sianara.txt', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :added, file: 'hello/kitty/what/che.txt', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :removed, file: 'hello/kitty/what/is/stewards.yml', deletions: 1))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    client.define_tree('base_head') do |tree|

      tree.file('hello/kitty/what/is/stewards.yml', <<-YAML)
        stewards:
          - xanderstrike
          - bleh
      YAML

      tree.file('hello/stewards.yml', <<-YAML)
        stewards:
          - xanderstrike
      YAML
    end

    expected_stewards_changes_view = build(:steward_changes_view,
                                           ref:           'base_head',
                                           stewards_file: 'hello/stewards.yml',
                                           changes:       [
                                                            build(:file_change, status: :added, file: 'hello/kitty/what/che.txt', additions: 1),
                                                            build(:file_change, status: :removed, file: 'hello/kitty/what/is/stewards.yml', deletions: 1),
                                                          ])

    expected_sub_stewards_changes_view = build(:steward_changes_view,
                                               ref:           'base_head',
                                               stewards_file: 'hello/kitty/what/is/stewards.yml',
                                               changes:       [
                                                                build(:file_change, status: :removed, file: 'hello/kitty/what/is/stewards.yml', deletions: 1),
                                                              ])

    notifier = mock
    notifier.expects(:notify)
      .with(deep_hash({
              'xanderstrike' => {
                'hello/stewards.yml' => [expected_stewards_changes_view],
                'hello/kitty/what/is/stewards.yml' => [expected_sub_stewards_changes_view]
              },
              'bleh'         => {
                'hello/kitty/what/is/stewards.yml' => [expected_sub_stewards_changes_view]
              }
            }))

    Ladle::PullHandler.new(client, notifier).handle(@pull_request)
  end

  test 'handle handles invalid stewards files ' do
    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, status: :added, file: 'one.rb', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    client.define_tree('base_head') do |tree|
      tree.file('sub/stewards.yml', <<-YAML)
        SOME WORDS
      YAML

      tree.file('stewards.yml', <<-YAML)
        stewards:
          - xanderstrike
          - fadsfadsfadsfadsf
      YAML
    end

    expected_stewards_changes_view = {
      'stewards.yml' => [build(:steward_changes_view,
                               ref:           'base_head',
                               stewards_file: 'stewards.yml',
                               changes:       [
                                                build(:file_change, status: :added, file: 'one.rb', additions: 1),
                                                build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
                                              ])]
    }

    notifier = mock
    notifier.expects(:notify)
      .with(deep_hash({
              'xanderstrike'      => expected_stewards_changes_view,
              'fadsfadsfadsfadsf' => expected_stewards_changes_view,
            }))

    Rails.logger.expects(:error).with(regexp_matches(/Error parsing file sub\/stewards.yml: Stewards file must contain a hash\n.*/))

    Ladle::PullHandler.new(client, notifier).handle(@pull_request)
  end

  test 'handle omits notifying of views/stewards without changes' do
    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, status: :added, file: 'hello/kitty/what/is/your/favorite_food.yml', additions: 1))
    changed_files.add_file_change(build(:file_change, status: :added, file: 'hello/kitty/what/is/your/name.txt', additions: 1))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    client.add_stewards_file(path: 'hello/stewards.yml', ref: 'base_head', contents: <<-YAML)
      stewards:
        - xanderstrike
        - github_username: bob
          include: "*.bin"
    YAML

    notifier = mock
    notifier.stubs(:id).returns(1)
    notifier.expects(:notify)
      .with(deep_hash({
                        'xanderstrike' => {
                          'hello/stewards.yml' => [build(:steward_changes_view,
                                                         ref:           'base_head',
                                                         stewards_file: 'hello/stewards.yml',
                                                         changes:       [
                                                                          build(:file_change, status: :added, file: 'hello/kitty/what/is/your/favorite_food.yml', additions: 1),
                                                                          build(:file_change, status: :added, file: 'hello/kitty/what/is/your/name.txt', additions: 1)
                                                                        ])],
                        },
                      }))

    Ladle::PullHandler.new(client, notifier).handle(@pull_request)
  end

  test "collect_changes" do
    tree = Ladle::PullHandler::StewardTree.new('xanderstrike')

    tree.add_rules(Ladle::StewardRules.new(ref:           'base',
                                           stewards_file: 'stewards.yml',
                                           file_filter:   Ladle::FileFilter.new))

    tree.add_rules(Ladle::StewardRules.new(ref:           'base',
                                           stewards_file: 'sub/stewards.yml',
                                           file_filter:   Ladle::FileFilter.new))

    tree.add_rules(Ladle::StewardRules.new(ref:           'base',
                                           stewards_file: 'sub3/stewards.yml',
                                           file_filter:   Ladle::FileFilter.new))

    stewards_trees = {}
    stewards_trees['xanderstrike'] = tree

    changed_files = Ladle::ChangedFiles.new
    changed_files.add_file_change(build(:file_change, file: 'stewards.yml'))
    changed_files.add_file_change(build(:file_change, file: 'one.rb'))
    changed_files.add_file_change(build(:file_change, file: 'sub/marine.rb'))
    changed_files.add_file_change(build(:file_change, file: 'sub/stewards.yml'))
    changed_files.add_file_change(build(:file_change, file: 'sub2/sandwich'))
    changed_files.add_file_change(build(:file_change, file: 'sub3/stewards.yml'))

    handler = Ladle::PullHandler.new(mock('client'), mock('notifier'))
    resolved_stewards_registry = handler.send(:collect_changes, stewards_trees, changed_files)

    expected_changes_view = build(:steward_changes_view,
      stewards_file: 'stewards.yml',
      changes:       [
                       build(:file_change, file: 'stewards.yml'),
                       build(:file_change, file: 'one.rb'),
                       build(:file_change, file: 'sub/marine.rb'),
                       build(:file_change, file: 'sub/stewards.yml'),
                       build(:file_change, file: 'sub2/sandwich'),
                       build(:file_change, file: 'sub3/stewards.yml')
                     ])

    assert_equal [expected_changes_view], resolved_stewards_registry['xanderstrike']['stewards.yml']

    expected_changes_view = build(:steward_changes_view,
      stewards_file: 'sub/stewards.yml',
      changes:       [
                       build(:file_change, file: 'sub/marine.rb'),
                       build(:file_change, file: 'sub/stewards.yml'),
                     ])

    assert_equal [expected_changes_view], resolved_stewards_registry['xanderstrike']['sub/stewards.yml']

    expected_changes_view = build(:steward_changes_view,
      stewards_file: 'sub3/stewards.yml',
      changes:       [
                       build(:file_change, file: 'sub3/stewards.yml')
                     ])

    assert_equal [expected_changes_view], resolved_stewards_registry['xanderstrike']['sub3/stewards.yml']
  end
end
