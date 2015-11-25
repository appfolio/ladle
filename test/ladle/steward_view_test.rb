require 'test_helper'
require 'ladle/steward_view'

class StewardViewTest < ActiveSupport::TestCase

  test 'value object' do
    changeset = Ladle::StewardsFileChangeset.new('stewards.yml',
                                                 [
                                                   build(:file_change, file: 'stewards.yml'),
                                                   build(:file_change, file: 'one.rb'),
                                                   build(:file_change, file: 'sub/marine.rb'),
                                                   build(:file_change, file: 'sub/stewards.yml'),
                                                   build(:file_change, file: 'sub2/sandwich'),
                                                   build(:file_change, file: 'sub3/stewards.yml')
                                                 ]
    )

    view1 = Ladle::StewardView.new
    view1.add_changeset(changeset)

    view2 = Ladle::StewardView.new
    view2.add_changeset(changeset.dup)

    assert_equal view1, view2
  end
end
