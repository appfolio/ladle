require 'test_helper'

require 'ladle/pull_request_change_collector'
require 'ladle/pull_request_info'
require 'ladle/changed_files'
require 'ladle/file_filter'
require 'ladle/steward_tree'
require 'ladle/steward_rules'

require 'ladle/stubbed_repo_client'

require 'assert_deep_hash'

class PullRequestChangeCollectorTest < ActiveSupport::TestCase
  include AssertDeepHash

  setup do
    user = create(:user)
    @repository = Repository.create!(name: 'xanderstrike/test', webhook_secret: 'whatever', access_via: user)
    @pull_request = create(:pull_request, repository: @repository, number: 30, html_url: 'www.test.com')
  end

  test 'returns an empty hash when there are no stewards' do
    changed_files = Ladle::ChangedFiles.new(
      build(:file_change, status: :added, file: 'one.rb'),
      build(:file_change, status: :modified, file: 'sub/marine.rb'))

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    assert_equal({}, Ladle::PullRequestChangeCollector.new(client).collect_changes(@pull_request))
  end

  test 'notifies stewards' do
    changed_files = Ladle::ChangedFiles.new(build(:file_change, status: :added, file: 'one.rb', additions: 1),
                                            build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1))

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

    expected = {
      'xanderstrike'      => Ladle::ChangesView.new(
        {
          rules:   Ladle::StewardRules.new(ref:           'base_head',
                                           stewards_file: 'stewards.yml'),
          changes: [
                     build(:file_change, status: :added, file: 'one.rb', additions: 1),
                     build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
                   ]
        },
        {
          rules:   Ladle::StewardRules.new(ref:           'base_head',
                                           stewards_file: 'sub/stewards.yml'),
          changes: [
                     build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
                   ]
        }
      ),
      'fadsfadsfadsfadsf' => Ladle::ChangesView.new(
        rules:   Ladle::StewardRules.new(ref:           'base_head',
                                         stewards_file: 'sub/stewards.yml'),
        changes: [
                   build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
                 ]
      ),
      'bob'               => Ladle::ChangesView.new(
        rules:   Ladle::StewardRules.new(ref:           'base_head',
                                         stewards_file: 'stewards.yml',
                                         file_filter:   Ladle::FileFilter.new(
                                           include_patterns: ["**.rb"],
                                           exclude_patterns: ["**.txt"]
                                         )),
        changes: [
                   build(:file_change, status: :added, file: 'one.rb', additions: 1),
                   build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
                 ]
      )
    }

    assert_deep_hash expected, Ladle::PullRequestChangeCollector.new(client).collect_changes(@pull_request)
  end

  test 'notifies steward from same file across branches' do
    changed_files = Ladle::ChangedFiles.new(
      build(:file_change, status: :added, file: 'file1.txt', additions: 1),
      build(:file_change, status: :added, file: 'file2.txt', additions: 1),
      build(:file_change, status: :modified, file: 'stewards.yml', additions: 1)
    )

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

    expected = {
      'someguy' => Ladle::ChangesView.new(
        {
          rules:   Ladle::StewardRules.new(ref:           'base_head',
                                           stewards_file: 'stewards.yml',
                                           file_filter:   Ladle::FileFilter.new(
                                             include_patterns: ["file1.txt"]
                                           ),
          ),
          changes: [
                     build(:file_change, status: :added, file: 'file1.txt', additions: 1)
                   ]
        },
        {
          rules:   Ladle::StewardRules.new(ref:           'branch_head',
                                           stewards_file: 'stewards.yml',
                                           file_filter:   Ladle::FileFilter.new(
                                             include_patterns: ["file2.txt"]
                                           ),
          ),
          changes: [
                     build(:file_change, status: :added, file: 'file2.txt', additions: 1)
                   ]
        }
      )
    }

    assert_deep_hash expected, Ladle::PullRequestChangeCollector.new(client).collect_changes(@pull_request)
  end

  test 'notifies old stewards' do
    changed_files = Ladle::ChangedFiles.new(
      build(:file_change, status: :removed, file: 'stewards.yml', deletions: 1),
      build(:file_change, status: :added, file: 'one.rb', additions: 1),
      build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1),
      build(:file_change, status: :modified, file: 'sub/stewards.yml', additions: 1),
      build(:file_change, status: :removed, file: 'sub2/sandwich', deletions: 1),
      build(:file_change, status: :added, file: 'sub2/stewards.yml', additions: 1),
      build(:file_change, status: :removed, file: 'sub3/stewards.yml', deletions: 1)
    )

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

    expected_stewards_changes_view = {
      rules:   Ladle::StewardRules.new(ref:           'base_head',
                                       stewards_file: 'stewards.yml',
      ),
      changes: [
                 build(:file_change, status: :removed, file: 'stewards.yml', deletions: 1),
                 build(:file_change, status: :added, file: 'one.rb', additions: 1),
                 build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1),
                 build(:file_change, status: :modified, file: 'sub/stewards.yml', additions: 1),
                 build(:file_change, status: :removed, file: 'sub2/sandwich', deletions: 1),
                 build(:file_change, status: :added, file: 'sub2/stewards.yml', additions: 1),
                 build(:file_change, status: :removed, file: 'sub3/stewards.yml', deletions: 1)
               ]
    }

    expected_branch_sub_stewards_changes_view = {
      rules:   Ladle::StewardRules.new(ref:           'branch_head',
                                       stewards_file: 'sub/stewards.yml',
      ),
      changes: [
                 build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1),
                 build(:file_change, status: :modified, file: 'sub/stewards.yml', additions: 1)
               ]
    }

    expected_base_sub_stewards_changes_view = {
      rules:   Ladle::StewardRules.new(ref:           'base_head',
                                       stewards_file: 'sub/stewards.yml',
      ),
      changes: [
                 build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1),
                 build(:file_change, status: :modified, file: 'sub/stewards.yml', additions: 1)
               ]
    }

    expected_sub2_stewards_changes_view = {
      rules:   Ladle::StewardRules.new(ref:           'branch_head',
                                       stewards_file: 'sub2/stewards.yml',
      ),
      changes: [
                 build(:file_change, status: :removed, file: 'sub2/sandwich', deletions: 1),
                 build(:file_change, status: :added, file: 'sub2/stewards.yml', additions: 1)

               ]
    }

    expected_sub3_stewards_changes_view = {
      rules:   Ladle::StewardRules.new(ref:           'base_head',
                                       stewards_file: 'sub3/stewards.yml',
      ),
      changes: [
                 build(:file_change, status: :removed, file: 'sub3/stewards.yml', deletions: 1)
               ]
    }

    expected = {
      'xanderstrike'      => Ladle::ChangesView.new(
        expected_stewards_changes_view,
        expected_branch_sub_stewards_changes_view,
        expected_sub3_stewards_changes_view
      ),
      'fadsfadsfadsfadsf' => Ladle::ChangesView.new(
        expected_branch_sub_stewards_changes_view,
      ),
      'bob'               => Ladle::ChangesView.new(
        expected_stewards_changes_view,
        expected_sub3_stewards_changes_view
      ),
      'jeb'               => Ladle::ChangesView.new(
        expected_base_sub_stewards_changes_view,
      ),
      'hamburglar'        => Ladle::ChangesView.new(
        expected_sub2_stewards_changes_view
      )
    }

    assert_deep_hash expected, Ladle::PullRequestChangeCollector.new(client).collect_changes(@pull_request)
  end

  test 'notify - stewards file not in changes_view' do
    changed_files = Ladle::ChangedFiles.new(
      build(:file_change, status: :added, file: 'goodbye/kitty/sianara.txt', additions: 1),
      build(:file_change, status: :added, file: 'hello/kitty/what/che.txt', additions: 1),
      build(:file_change, status: :removed, file: 'hello/kitty/what/is/stewards.yml', deletions: 1)
    )

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

    expected_stewards_changes_view = {
      rules:   Ladle::StewardRules.new(ref:           'base_head',
                                       stewards_file: 'hello/stewards.yml',
      ),
      changes: [
                 build(:file_change, status: :added, file: 'hello/kitty/what/che.txt', additions: 1),
                 build(:file_change, status: :removed, file: 'hello/kitty/what/is/stewards.yml', deletions: 1),
               ]
    }

    expected_sub_stewards_changes_view = {
      rules:   Ladle::StewardRules.new(ref:           'base_head',
                                       stewards_file: 'hello/kitty/what/is/stewards.yml',
      ),
      changes: [
                 build(:file_change, status: :removed, file: 'hello/kitty/what/is/stewards.yml', deletions: 1),
               ]
    }

    expected = {
      'xanderstrike' => Ladle::ChangesView.new(
        expected_stewards_changes_view,
        expected_sub_stewards_changes_view
      ),
      'bleh'         => Ladle::ChangesView.new(
        expected_sub_stewards_changes_view
      ),
    }

    assert_deep_hash expected, Ladle::PullRequestChangeCollector.new(client).collect_changes(@pull_request)
  end

  test 'handle handles invalid stewards files ' do
    changed_files = Ladle::ChangedFiles.new(
      build(:file_change, status: :added, file: 'one.rb', additions: 1),
      build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1)
    )

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

    expected_stewards_changes_view = Ladle::ChangesView.new(
      rules:   Ladle::StewardRules.new(ref:           'base_head',
                                       stewards_file: 'stewards.yml'),
      changes: [
                 build(:file_change, status: :added, file: 'one.rb', additions: 1),
                 build(:file_change, status: :modified, file: 'sub/marine.rb', additions: 1, deletions: 1),
               ]
    )

    expected = {
      'xanderstrike'      => expected_stewards_changes_view,
      'fadsfadsfadsfadsf' => expected_stewards_changes_view,
    }

    Rails.logger.expects(:error).with(regexp_matches(/Error parsing file sub\/stewards.yml: Stewards file must contain a hash\n.*/))

    assert_deep_hash expected, Ladle::PullRequestChangeCollector.new(client).collect_changes(@pull_request)
  end

  test 'handle omits notifying of views/stewards without changes' do
    changed_files = Ladle::ChangedFiles.new(
      build(:file_change, status: :added, file: 'hello/kitty/what/is/your/favorite_food.yml', additions: 1),
      build(:file_change, status: :added, file: 'hello/kitty/what/is/your/name.txt', additions: 1)
    )

    client = Ladle::StubbedRepoClient.new(@pull_request.number, Ladle::PullRequestInfo.new('branch_head', 'base_head'), changed_files)

    client.add_stewards_file(path: 'hello/stewards.yml', ref: 'base_head', contents: <<-YAML)
      stewards:
        - xanderstrike
        - github_username: bob
          include: "*.bin"
    YAML

    expected = {
      'xanderstrike' => Ladle::ChangesView.new(
        rules:   Ladle::StewardRules.new(ref:           'base_head',
                                         stewards_file: 'hello/stewards.yml'),
        changes: [
                   build(:file_change, status: :added, file: 'hello/kitty/what/is/your/favorite_food.yml', additions: 1),
                   build(:file_change, status: :added, file: 'hello/kitty/what/is/your/name.txt', additions: 1)
                 ]
      )
    }

    assert_deep_hash expected, Ladle::PullRequestChangeCollector.new(client).collect_changes(@pull_request)
  end

  test "append_changes" do
    tree = Ladle::StewardTree.new([
      Ladle::StewardRules.new(ref:           'base',
                              stewards_file: 'stewards.yml',
                              file_filter:   Ladle::FileFilter.new),

      Ladle::StewardRules.new(ref:           'base',
                              stewards_file: 'sub/stewards.yml',
                              file_filter:   Ladle::FileFilter.new),

      Ladle::StewardRules.new(ref:           'base',
                              stewards_file: 'sub3/stewards.yml',
                              file_filter:   Ladle::FileFilter.new),

      Ladle::StewardRules.new(ref:           'base',
                              stewards_file: 'sub4/stewards.yml',
                              file_filter:   Ladle::FileFilter.new)
    ])

    stewards_trees = {}
    stewards_trees['xanderstrike'] = tree

    changed_files = Ladle::ChangedFiles.new(
      build(:file_change, file: 'stewards.yml'),
      build(:file_change, file: 'one.rb'),
      build(:file_change, file: 'sub/marine.rb'),
      build(:file_change, file: 'sub/stewards.yml'),
      build(:file_change, file: 'sub2/sandwich'),
      build(:file_change, file: 'sub3/stewards.yml')
    )

    handler = Ladle::PullRequestChangeCollector.new(mock('client'))
    resolved_stewards_registry = handler.send(:append_changes, stewards_trees, changed_files)

    expected_changes_view = Ladle::ChangesView.new(
      {
        rules:   Ladle::StewardRules.new(ref:           'base',
                                         stewards_file: 'stewards.yml'),
        changes: [
                   build(:file_change, file: 'stewards.yml'),
                   build(:file_change, file: 'one.rb'),
                   build(:file_change, file: 'sub/marine.rb'),
                   build(:file_change, file: 'sub/stewards.yml'),
                   build(:file_change, file: 'sub2/sandwich'),
                   build(:file_change, file: 'sub3/stewards.yml')
                 ]
      },
      {
        rules:   Ladle::StewardRules.new(ref:           'base',
                                         stewards_file: 'sub/stewards.yml'),
        changes: [
                   build(:file_change, file: 'sub/marine.rb'),
                   build(:file_change, file: 'sub/stewards.yml'),
                 ]
      },
      {
        rules:   Ladle::StewardRules.new(ref:           'base',
                                         stewards_file: 'sub3/stewards.yml'),
        changes: [
                   build(:file_change, file: 'sub3/stewards.yml')
                 ]
      }
    )

    assert_equal expected_changes_view, resolved_stewards_registry['xanderstrike']
  end
end
