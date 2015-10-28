require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "from_omniauth updates token" do
    user = User.create!(email: 'bleh@bleh.com', password: 'blehbleh', provider: "bleh", uid: "123", token: 'a')
    auth = mock(provider: user.provider, uid: user.uid, credentials: mock(token: 'B'))

    user_from_omniauth = User.from_omniauth(auth)

    assert_equal user, user_from_omniauth
    assert_equal 'B', user_from_omniauth.token
  end
end
