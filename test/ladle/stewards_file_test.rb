require 'test_helper'
require 'ladle/stewards_file'

class StewardsFileTest < ActiveSupport::TestCase

  test 'parse empty' do
    raised = assert_raises StandardError do
      Ladle::StewardsFile.parse("")
    end

    assert_equal "Cannot parse empty file", raised.message
  end

  test 'parse basic file' do
    content = <<-YAML
      stewards:
        - xanderstrike
        - bob
    YAML

    stewards_file = Ladle::StewardsFile.parse(content)

    expected_stewards = [
      Ladle::StewardsFile::Steward.new(github_username: "xanderstrike"),
      Ladle::StewardsFile::Steward.new(github_username: "bob"),
    ]

    assert_equal expected_stewards, stewards_file.stewards
  end

  test 'parse steward rules' do
    content = <<-YAML
      stewards:
       - github_username: xanderstrike
         include:
           - "**/bleh"
           - "**/whatever"
         exclude:
           - "**/bleh/*.rb"
       - bob
    YAML

    stewards_file = Ladle::StewardsFile.parse(content)

    expected_stewards = [
      Ladle::StewardsFile::Steward.new(github_username: "xanderstrike", include_patterns: ["**/bleh", "**/whatever"], exclude_patterns: ["**/bleh/*.rb"]),
      Ladle::StewardsFile::Steward.new(github_username: "bob"),
    ]

    assert_equal expected_stewards, stewards_file.stewards
  end
end
