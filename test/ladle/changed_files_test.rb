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

    change1 = build(:file_change, file: "bob/loblaw/law.blog")
    changed_files = changed_files.add_file_change(change1)
    assert_equal [Pathname.new('bob/loblaw'), Pathname.new('bob'), Pathname.new('.')], changed_files.directories
    assert_equal [], changed_files.modified_stewards_files

    assert_equal [change1], changed_files.file_changes_in(Pathname.new("bob/loblaw"))
    assert_equal [change1], changed_files.file_changes_in(Pathname.new("bob"))
    assert_equal [change1], changed_files.file_changes_in(Pathname.new(""))
    assert_equal [change1], changed_files.file_changes_in(Pathname.new("."))
    assert_equal [change1], changed_files.file_changes_in(Pathname.new("./"))

    assert_equal [], changed_files.file_changes_in(Pathname.new("bob/loblaw/inlaw"))
    assert_equal [], changed_files.file_changes_in(Pathname.new("bob2"))

    change2 = build(:file_change, file: "bob/loblaw/law2.blog")
    changed_files = changed_files.add_file_change(change2)

    change3 = build(:file_change, file: "bob_rob/inlaw/law.blog")
    changed_files = changed_files.add_file_change(change3)

    change4 = build(:file_change, file: "law.blog")
    changed_files = changed_files.add_file_change(change4)

    assert_equal [change1, change2], changed_files.file_changes_in(Pathname.new("bob/loblaw"))
    assert_equal [change1, change2], changed_files.file_changes_in(Pathname.new("bob"))
    assert_equal [change1, change2, change4, change3].map(&:file), changed_files.file_changes_in(Pathname.new("")).map(&:file)
  end

  test 'modified_stewards_files' do
    changed_files = Ladle::ChangedFiles.new

    added_stewards_file = build(:file_change, status: :added, file: "bob/loblaw/stewards.yml")
    changed_files = changed_files.add_file_change(added_stewards_file)
    assert_equal [Pathname.new("bob/loblaw/stewards.yml")], changed_files.modified_stewards_files

    removed_stewards_file = build(:file_change, status: :removed, file: "bob/loblaw/stewards.yml")
    changed_files = changed_files.add_file_change(removed_stewards_file)
    assert_equal [Pathname.new("bob/loblaw/stewards.yml")], changed_files.modified_stewards_files

    modified_stewards_file = build(:file_change, status: :modified, file: "bob/stewards.yml")
    changed_files = changed_files.add_file_change(modified_stewards_file)
    assert_equal [Pathname.new("bob/loblaw/stewards.yml"), Pathname.new("bob/stewards.yml")], changed_files.modified_stewards_files
  end

  test 'directories' do
    changed_files = Ladle::ChangedFiles.new

    changed_files = changed_files.add_file_change(build(:file_change, file: "bob/loblaw/law.blog"))
    changed_files = changed_files.add_file_change(build(:file_change, file: "bob/loblaw/law2.blog"))
    changed_files = changed_files.add_file_change(build(:file_change, file: "bob_rob/inlaw/law.blog"))
    changed_files = changed_files.add_file_change(build(:file_change, file: "loblaw/law.blog"))
    changed_files = changed_files.add_file_change(build(:file_change, file: "law.blog"))

    expected = [
      Pathname.new('loblaw'),
      Pathname.new('bob_rob/inlaw'),
      Pathname.new('bob_rob'),
      Pathname.new('bob/loblaw'),
      Pathname.new('bob'),
      Pathname.new('.'),
    ]
    assert_equal expected, changed_files.directories
  end
end
