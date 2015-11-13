require 'test_helper'

class FileChangeTest < ActiveSupport::TestCase

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
