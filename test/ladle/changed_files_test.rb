require 'test_helper'
require 'ladle/changed_files'

class ChangedFilesTest < ActiveSupport::TestCase

  test 'empty' do
    changed_files = Ladle::ChangedFiles.new

    assert_equal [], changed_files.file_changes_in("bleh")
    assert_equal [], changed_files.directories
    assert_equal [], changed_files.modified_stewards_files
  end

  test 'add some changes' do
    changed_files = Ladle::ChangedFiles.new

    change1 = Ladle::FileChange.new(:added, "bob/loblaw/law.blog")
    changed_files.add_file_change(change1)
    assert_equal [Pathname.new('bob/loblaw')], changed_files.directories
    assert_equal [], changed_files.modified_stewards_files

    assert_equal [change1], changed_files.file_changes_in(Pathname.new("bob/loblaw"))
    assert_equal [change1], changed_files.file_changes_in(Pathname.new("bob"))
    assert_equal [change1], changed_files.file_changes_in(Pathname.new(""))
    assert_equal [change1], changed_files.file_changes_in(Pathname.new("."))
    assert_equal [change1], changed_files.file_changes_in(Pathname.new("./"))

    assert_equal [], changed_files.file_changes_in(Pathname.new("bob/loblaw/inlaw"))
    assert_equal [], changed_files.file_changes_in(Pathname.new("bob2"))

    change2 = Ladle::FileChange.new(:added, "bob/loblaw/law2.blog")
    changed_files.add_file_change(change2)

    change3 = Ladle::FileChange.new(:added, "bob_rob/inlaw/law.blog")
    changed_files.add_file_change(change3)

    change4 = Ladle::FileChange.new(:added, "law.blog")
    changed_files.add_file_change(change4)

    assert_equal [change1, change2], changed_files.file_changes_in(Pathname.new("bob/loblaw"))
    assert_equal [change1, change2], changed_files.file_changes_in(Pathname.new("bob"))
    assert_equal [change1, change2, change3, change4], changed_files.file_changes_in(Pathname.new(""))
  end

  test 'directories' do
    changed_files = Ladle::ChangedFiles.new

    changed_files.add_file_change(Ladle::FileChange.new(:added, "bob/loblaw/law.blog"))
    changed_files.add_file_change(Ladle::FileChange.new(:added, "bob/loblaw/law2.blog"))
    changed_files.add_file_change(Ladle::FileChange.new(:added, "bob_rob/inlaw/law.blog"))
    changed_files.add_file_change(Ladle::FileChange.new(:added, "loblaw/law.blog"))
    changed_files.add_file_change(Ladle::FileChange.new(:added, "law.blog"))

    expected = [
      Pathname.new('loblaw'),
      Pathname.new('bob_rob/inlaw'),
      Pathname.new('bob/loblaw'),
      Pathname.new('.'),
    ]
    assert_equal expected, changed_files.directories
  end
end
