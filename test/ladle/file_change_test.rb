require 'test_helper'

class FileChangeTest < ActiveSupport::TestCase

  test 'value object' do
    file_change1 = Ladle::FileChange.new(:removed, "bleh.rb")
    file_change2 = Ladle::FileChange.new(:removed, "bleh.rb")
    assert_equal file_change1, file_change2
    assert file_change2.eql?(file_change1)
    assert file_change1.eql?(file_change2)
    assert file_change1.hash, file_change2.hash

    file_change3 = Ladle::FileChange.new(:added, "bleh.rb")
    assert_not_equal file_change1, file_change3
  end

  test 'status_initial' do
    file_change = Ladle::FileChange.new(:removed, "bleh.rb")
    assert_equal "D", file_change.status_initial

    file_change = Ladle::FileChange.new(:modified, "bleh.rb")
    assert_equal "M", file_change.status_initial

    file_change = Ladle::FileChange.new(:added, "bleh.rb")
    assert_equal "A", file_change.status_initial
  end

  test 'invalid' do
    raised = assert_raises ArgumentError do
      Ladle::FileChange.new(:hey, "bleh.rb")
    end

    assert_equal "Invalid status: 'hey'", raised.message
  end
end
