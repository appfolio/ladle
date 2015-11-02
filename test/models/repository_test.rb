require 'test_helper'

class RepositoryTest < ActiveSupport::TestCase
  test 'validations' do
    repo = Repository.new
    refute repo.valid?
    assert_equal({ name: ["can't be blank"], webhook_secret: ["can't be blank"], access_token: ["can't be blank"] }, repo.errors.messages)
  end
end
