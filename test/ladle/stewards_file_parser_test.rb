require 'test_helper'
require 'ladle/stewards_file_parser'
require 'ladle/steward_config'

class StewardsFileParserTest < ActiveSupport::TestCase

  test 'parse empty' do
    raised = assert_raises Ladle::StewardsFileParser::ParsingError do
      Ladle::StewardsFileParser.parse("")
    end

    assert_equal "Cannot parse empty file", raised.message
  end

  test 'parse basic file' do
    content = <<-YAML
      stewards:
        - xanderstrike
        - bob
    YAML

    stewards_file = Ladle::StewardsFileParser.parse(content)

    expected_stewards = [
      Ladle::StewardConfig.new(github_username: "xanderstrike"),
      Ladle::StewardConfig.new(github_username: "bob"),
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
         exclude: "**/bleh/*.rb"
       - bob
    YAML

    stewards_file = Ladle::StewardsFileParser.parse(content)

    expected_stewards = [
      Ladle::StewardConfig.new(github_username: "xanderstrike", include_patterns: ["**/bleh", "**/whatever"], exclude_patterns: ["**/bleh/*.rb"]),
      Ladle::StewardConfig.new(github_username: "bob"),
    ]

    assert_equal expected_stewards, stewards_file.stewards
  end

  test 'parse steward rules - missing required key' do
    content = <<-YAML
      stewards:
       - name: xanderstrike
    YAML

    raised = assert_raises Ladle::StewardsFileParser::ParsingError do
      Ladle::StewardsFileParser.parse(content)
    end

    assert_equal "Missing required key: github_username", raised.message
  end
end
