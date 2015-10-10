require 'test_helper'
require 'pull_handler'

class PullHandlerTest < ActiveSupport::TestCase
  include VCRHelpers

  test 'stores the repo and number' do
    ph = PullHandler.new(repo: 'a', number: 1)
    assert_equal 'a', ph.instance_variable_get('@repo')
    assert_equal 1, ph.instance_variable_get('@number')
  end

  test 'gets the stewards and posts a comment' do
    using_vcr do
      PullHandler.new(repo: 'xanderstrike/test', number: 1).handle
    end
  end
end
