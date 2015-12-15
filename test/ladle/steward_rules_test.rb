require 'test_helper'

class StewardRulesTest < ActiveSupport::TestCase

  test 'value object' do
    rules1 = build(:steward_rules)

    rules2 = build(:steward_rules)

    assert_equal rules1, rules2
    assert rules1.eql?(rules2)
    assert rules2.eql?(rules1)
    assert rules1.hash, rules2.hash
  end
end
