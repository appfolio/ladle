require 'test_helper'
require 'ladle/file_filter'

class StewardChangesViewTest < ActiveSupport::TestCase

  test 'value object' do
    changes_view1 = build(:steward_changes_view, changes: [
                                                            build(:file_change, status: :modified, file: "app/modified_file.rb"),
                                                            build(:file_change, status: :added, file: "app/new_file.rb"),
                                                            build(:file_change, status: :removed, file: "app/removed_file.rb"),
                                                          ])

    changes_view2 = build(:steward_changes_view, changes: [
                                                            build(:file_change, status: :removed, file: "app/removed_file.rb"),
                                                            build(:file_change, status: :added, file: "app/new_file.rb"),
                                                            build(:file_change, status: :modified, file: "app/modified_file.rb"),
                                                          ])

    assert_equal changes_view1, changes_view2
    assert changes_view1.eql?(changes_view2)
    assert changes_view2.eql?(changes_view1)
    assert changes_view1.hash, changes_view2.hash
  end

  test 'add_file_changes' do
    view = build(:steward_changes_view,
                 file_filter: Ladle::FileFilter.new(
                   include_patterns: ["**/*.rb"],
                   exclude_patterns: ["dir1/dir2/dir3/file.rb"]
                 ))

    file_changes = [
      build(:file_change, file: "dir1/file.rb"),
      build(:file_change, file: "dir1/dir2/dir3/file.rb"),
      build(:file_change, file: "dir1/dir2/dir3/file.txt"),
      build(:file_change, file: "dir1/dir2/dir3/file2.rb")
    ]

    view.add_file_changes(file_changes)

    assert_equal [build(:file_change, file: "dir1/file.rb"), build(:file_change, file: "dir1/dir2/dir3/file2.rb")], view.changes
  end
end
