require 'test_helper'

class UserTest < ActiveSupport::TestCase

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
