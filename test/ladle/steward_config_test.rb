require 'test_helper'
require 'ladle/steward_config'
require 'ladle/file_filter'

class StewardConfigTest < ActiveSupport::TestCase

  test 'value object' do
    config1 = Ladle::StewardConfig.new(github_username: "xanderstrike", include_patterns: ["**/bleh", "**/whatever"], exclude_patterns: ["**/bleh/*.rb"])
    config2 = Ladle::StewardConfig.new(github_username: "xanderstrike", include_patterns: ["**/bleh", "**/whatever"], exclude_patterns: ["**/bleh/*.rb"])

    assert_equal config1, config2
    assert config1.eql?(config2)
    assert config2.eql?(config1)
    assert config1.hash, config2.hash
  end
  
  test 'creates FileFilter' do
    config = Ladle::StewardConfig.new(github_username: "xanderstrike", include_patterns: ["**/bleh", "**/whatever"], exclude_patterns: ["**/bleh/*.rb"])

    assert_equal Ladle::FileFilter.new(include_patterns: ["**/bleh", "**/whatever"], exclude_patterns: ["**/bleh/*.rb"]), config.file_filter
  end
end

