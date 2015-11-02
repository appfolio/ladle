require 'test_helper'

class PullRequestTest < ActiveSupport::TestCase
  test 'has validations' do
    pr = PullRequest.create
    refute pr.valid?
    assert_equal({ number: ["can't be blank"], repo: ["can't be blank"] }, pr.errors.messages)
  end
end
