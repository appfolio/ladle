require 'test_helper'
require 'ladle/steward_view'

class StewardViewTest < ActiveSupport::TestCase

  test 'value object' do
    change_view = build(:steward_changes_view,
                        stewards_file: 'stewards.yml',
                        changes:       [
                                         build(:file_change, file: 'stewards.yml'),
                                         build(:file_change, file: 'one.rb'),
                                         build(:file_change, file: 'sub/marine.rb'),
                                         build(:file_change, file: 'sub/stewards.yml'),
                                         build(:file_change, file: 'sub2/sandwich'),
                                         build(:file_change, file: 'sub3/stewards.yml')
                                       ]
    )

    view1 = Ladle::StewardView.new
    view1.add_change_view(change_view)

    view2 = Ladle::StewardView.new
    view2.add_change_view(change_view.dup)

    assert_equal view1, view2
  end
end
