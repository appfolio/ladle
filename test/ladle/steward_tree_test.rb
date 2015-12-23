require 'test_helper'

require 'ladle/steward_tree'
require 'ladle/steward_rules'
require 'ladle/changed_files'

class StewardTreeTest < ActiveSupport::TestCase
  test 'changes selected from rules' do
    changed_files = Ladle::ChangedFiles.new(
      build(:file_change, file: 'stewards.yml'),
      build(:file_change, file: 'one.rb'),
      build(:file_change, file: 'sub/marine.rb'),
      build(:file_change, file: 'sub/stewards.yml'),
      build(:file_change, file: 'sub2/sandwich'),
      build(:file_change, file: 'sub3/stewards.yml')
    )

    sub_rules = Ladle::StewardRules.new(ref:           'base',
                                        stewards_file: 'sub/stewards.yml')

    sub4_rules = Ladle::StewardRules.new(ref:           'base',
                                         stewards_file: 'sub4/stewards.yml')

    tree = Ladle::StewardTree.new([
                                    sub_rules,
                                    sub4_rules
                                  ])

    expected_rules_and_changes = [
      [
        sub_rules,
        [
          build(:file_change, file: 'sub/marine.rb'),
          build(:file_change, file: 'sub/stewards.yml')
        ]
      ]
    ]

    assert_equal expected_rules_and_changes, tree.changes(changed_files).to_a
  end
end
