require 'test_helper'

class RepositoryTest < ActiveSupport::TestCase
  test 'validations' do
    repo = Repository.new
    refute repo.valid?
    assert_equal({ name: ["can't be blank"], webhook_secret: ["can't be blank"], access_via: ["can't be blank"] }, repo.errors.messages)
  end
  
  test 'access_token delegated to user' do
    user = User.create!(email: 'test@test.com', password: 'hunter234', token: 'hello')
    repo = Repository.create!(name: 'bleh/bleh', webhook_secret: 'asdf', access_via: user)
    assert_equal 'hello', repo.access_token
  end
end
