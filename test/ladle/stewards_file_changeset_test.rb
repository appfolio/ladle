require 'test_helper'

class StewardsFileChangesetTest < ActiveSupport::TestCase

  test 'value object' do
    changeset1 = Ladle::StewardsFileChangeset.new('app/stewards.yml',
                                                  [
                                                    build(:file_change, status: :modified, file: "app/modified_file.rb"),
                                                    build(:file_change, status: :added, file: "app/new_file.rb"),
                                                    build(:file_change, status: :removed, file: "app/removed_file.rb"),
                                                  ])

    changeset2 = Ladle::StewardsFileChangeset.new('app/stewards.yml',
                                                  [
                                                    build(:file_change, status: :removed, file: "app/removed_file.rb"),
                                                    build(:file_change, status: :added, file: "app/new_file.rb"),
                                                    build(:file_change, status: :modified, file: "app/modified_file.rb"),
                                                  ])

    assert_equal changeset1, changeset2
    assert changeset1.eql?(changeset2)
    assert changeset2.eql?(changeset1)
    assert changeset1.hash, changeset2.hash
  end
end
