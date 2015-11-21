require 'test_helper'

class FileChangeTest < ActiveSupport::TestCase

  test 'value object' do
    file_change1 = build(:file_change, status: :removed, file: "bleh.rb")
    file_change2 = build(:file_change, status: :removed, file: "bleh.rb")
    assert_equal file_change1, file_change2
    assert file_change2.eql?(file_change1)
    assert file_change1.eql?(file_change2)
    assert file_change1.hash, file_change2.hash

    file_change3 = build(:file_change, status: :added, file: "bleh.rb")
    assert_not_equal file_change1, file_change3
  end

  test 'status_initial' do
    file_change = build(:file_change, status: :removed, file: "bleh.rb")
    assert_equal "D", file_change.status_initial

    file_change = build(:file_change, status: :modified, file: "bleh.rb")
    assert_equal "M", file_change.status_initial

    file_change = build(:file_change, status: :added, file: "bleh.rb")
    assert_equal "A", file_change.status_initial
  end

  test 'changes_count' do
    file_change = build(:file_change, additions: 1, deletions: 2, changes: 3)
    assert_equal 6, file_change.changes_count
  end

  test 'invalid' do
    raised = assert_raises ArgumentError do
      build(:file_change, status: :hey)
    end

    assert_equal "Invalid status: 'hey'", raised.message
  end
end
