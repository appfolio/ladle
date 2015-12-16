require 'test_helper'
require 'ladle/steward_rules'
require 'ladle/changes_view'
require 'ladle/changed_files'

class ChangesViewTest < ActiveSupport::TestCase

  setup :create_file_changes

  test 'comparable' do
    changes_view1 = build(:changes_view,
                          changes: [
                                     {
                                       rules:   Ladle::StewardRules.new(ref:           'base',
                                                                        stewards_file: 'app/stewards.yml'),
                                       changes: [
                                                  build(:file_change, status: :modified, file: "app/modified_file.rb"),
                                                  build(:file_change, status: :added, file: "app/new_file.rb"),
                                                  build(:file_change, status: :removed, file: "app/removed_file.rb"),
                                                ]
                                     }
                                   ])


    changes_view2 = build(:changes_view,
                          changes: [
                                     {
                                       rules:   Ladle::StewardRules.new(ref:           'base',
                                                                        stewards_file: 'app/stewards.yml'),
                                       changes: [
                                                  build(:file_change, status: :modified, file: "app/modified_file.rb"),
                                                  build(:file_change, status: :added, file: "app/new_file.rb"),
                                                  build(:file_change, status: :removed, file: "app/removed_file.rb"),
                                                ]
                                     }
                                   ])

    assert_equal changes_view1, changes_view2
    assert changes_view1.eql?(changes_view2)
    assert changes_view2.eql?(changes_view1)
  end

  test 'empty?' do
    changes_view = Ladle::ChangesView.new
    assert_predicate changes_view, :empty?

    rules = Ladle::StewardRules.new(ref:           'base',
                                    stewards_file: 'stewards.yml')

    changes_view.add_changes(rules, @file_changes)
    refute_predicate changes_view, :empty?
  end

  test 'enumerates in order' do
    changes_view = Ladle::ChangesView.new

    rules_list = [
      Ladle::StewardRules.new(ref:           'base',
                              stewards_file: 'sub1/sub2/stewards.yml'),
      Ladle::StewardRules.new(ref:           'base',
                              stewards_file: 'stewards.yml'),
      Ladle::StewardRules.new(ref:           'base',
                              stewards_file: 'sub3/stewards.yml'),
    ]

    rules_list.each do |rules|
      changes_view.add_changes(rules, @file_changes)
    end

    expected_order = [
      'stewards.yml',
      'sub1/sub2/stewards.yml',
      'sub3/stewards.yml',
    ]

    assert_equal expected_order, changes_view.to_a.map(&:first).map(&:stewards_file).map(&:to_s)
  end

  test 'rules with same file and same changes are collapsed' do
    changes_view = Ladle::ChangesView.new

    base_rules = Ladle::StewardRules.new(ref:           'base',
                                         stewards_file: 'stewards.yml')

    changes_view.add_changes(base_rules, @file_changes)

    bleh_rules = Ladle::StewardRules.new(ref:           'bleh',
                                         stewards_file: 'stewards.yml')

    changes_view.add_changes(bleh_rules, @file_changes)
    assert_equal [[base_rules, @file_changes]], changes_view.to_a
  end

  test 'rules with same changes but different file are not collapsed' do
    changes_view = Ladle::ChangesView.new

    base_rules = Ladle::StewardRules.new(ref:           'base',
                                         stewards_file: 'stewards.yml')

    changes_view.add_changes(base_rules, @file_changes)

    bleh_rules = Ladle::StewardRules.new(ref:           'bleh',
                                         stewards_file: 'sub/stewards.yml')

    changes_view.add_changes(bleh_rules, @file_changes)
    assert_equal [[base_rules, @file_changes], [bleh_rules, @file_changes]], changes_view.to_a
  end

  private

  def create_file_changes
    @file_changes = []
    @file_changes << build(:file_change, file: 'stewards.yml')
    @file_changes << build(:file_change, file: 'one.rb')
  end
end
