require 'test_helper'
require 'ladle/file_filter'

class FileFilterTest < ActiveSupport::TestCase

  test 'include? - empty' do
    file_filter = Ladle::FileFilter.new(
      include_patterns: [],
      exclude_patterns: []
    )

    assert file_filter.include?(Pathname.new("dir1/file.rb"))
    assert file_filter.include?(Pathname.new("dir1/dir2/dir3/file.rb"))
    assert file_filter.include?(Pathname.new("dir1/dir2/dir3/file.txt"))
    assert file_filter.include?(Pathname.new("dir1/dir2/dir3/file2.rb"))
    assert file_filter.include?(Pathname.new("dir2/dir2.rb"))
  end

  test 'include? - include and exclude' do
    file_filter = Ladle::FileFilter.new(
      include_patterns: ["dir1/**.rb"],
      exclude_patterns: ["dir1/dir2/dir3/file.rb"]
    )

    assert file_filter.include?(Pathname.new("dir1/file.rb"))
    refute file_filter.include?(Pathname.new("dir1/dir2/dir3/file.rb"))
    refute file_filter.include?(Pathname.new("dir1/dir2/dir3/file.txt"))
    assert file_filter.include?(Pathname.new("dir1/dir2/dir3/file2.rb"))
    refute file_filter.include?(Pathname.new("dir2/dir2.rb"))
  end

  test 'include? - include' do
    file_filter = Ladle::FileFilter.new(
      include_patterns: ["dir1/**.rb"],
      exclude_patterns: []
    )

    assert file_filter.include?(Pathname.new("dir1/file.rb"))
    assert file_filter.include?(Pathname.new("dir1/dir2/dir3/file.rb"))
    refute file_filter.include?(Pathname.new("dir1/dir2/dir3/file.txt"))
    assert file_filter.include?(Pathname.new("dir1/dir2/dir3/file2.rb"))
    refute file_filter.include?(Pathname.new("dir2/dir2.rb"))
  end

  test 'include? - exclude' do
    file_filter = Ladle::FileFilter.new(
      include_patterns: [],
      exclude_patterns: ["dir1/dir2/dir3/file.rb"]
    )

    assert file_filter.include?(Pathname.new("dir1/file.rb"))
    refute file_filter.include?(Pathname.new("dir1/dir2/dir3/file.rb"))
    assert file_filter.include?(Pathname.new("dir1/dir2/dir3/file.txt"))
    assert file_filter.include?(Pathname.new("dir1/dir2/dir3/file2.rb"))
    assert file_filter.include?(Pathname.new("dir2/dir2.rb"))
  end
end
