require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "devise validations" do
    # test presence
    user = User.new
    refute_predicate user, :valid?

    assert_equal [:email, :password], user.errors.keys

    user.errors.each do |attribute, messages|
      assert_equal "can't be blank", messages, attribute
    end

    user.email = 'hey@ho.com'
    user.password = '12345678'
    assert_predicate user, :valid?

    user.save!

    # test format
    user.email = 'barf'
    refute_predicate user, :valid?

    assert_equal [:email], user.errors.keys
    assert_equal ["is invalid"], user.errors[:email]

    # test uniqueness
    user = User.create(email: 'hey@ho.com', password: '12345678')
    refute_predicate user, :valid?

    assert_equal [:email], user.errors.keys
    assert_equal ["has already been taken"], user.errors[:email]
  end

  test "from_omniauth creates user" do
    auth = stub(provider: 'github',
                uid: '9213874908137481237',
                credentials: stub(token: 'B'),
                info: stub(nickname: "daman", email: 'bleh@bleh.com'))

    Devise.expects(:friendly_token).returns("123456789012345678901234567890")

    user = User.from_omniauth(auth)

    assert_equal 'github', user.provider
    assert_equal '9213874908137481237', user.uid
    assert_equal 'daman', user.github_username
    assert_equal 'bleh@bleh.com', user.email
    assert_equal 'B', user.token
    assert_equal '12345678901234567890', user.password
  end

  test "from_omniauth updates token" do
    user = User.create!(email: 'bleh@bleh.com', password: 'blehbleh', provider: "bleh", uid: "123", token: 'a')
    auth = mock(provider: user.provider, uid: user.uid, credentials: mock(token: 'B'))

    user_from_omniauth = User.from_omniauth(auth)

    assert_equal user, user_from_omniauth
    assert_equal 'B', user_from_omniauth.token
  end
end
