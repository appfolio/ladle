require 'test_helper'

class StewardChangesViewTest < ActiveSupport::TestCase

  test 'value object' do
    changes_view1 = Ladle::StewardChangesView.new('app/stewards.yml',
                                                  [
                                                    build(:file_change, status: :modified, file: "app/modified_file.rb"),
                                                    build(:file_change, status: :added, file: "app/new_file.rb"),
                                                    build(:file_change, status: :removed, file: "app/removed_file.rb"),
                                                  ])

    changes_view2 = Ladle::StewardChangesView.new('app/stewards.yml',
                                                  [
                                                    build(:file_change, status: :removed, file: "app/removed_file.rb"),
                                                    build(:file_change, status: :added, file: "app/new_file.rb"),
                                                    build(:file_change, status: :modified, file: "app/modified_file.rb"),
                                                  ])

    assert_equal changes_view1, changes_view2
    assert changes_view1.eql?(changes_view2)
    assert changes_view2.eql?(changes_view1)
    assert changes_view1.hash, changes_view2.hash
  end
end
