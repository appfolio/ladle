if Rails.env.development? && ! ENV['MOCK_OMNIAUTH'].nil?
  token = '1ea7ca751ea7ca751ea7ca751ea7ca75'

  OmniAuth.config.test_mode = true

  OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
    provider:    'github',
    uid:         '1ea7ca75',
    info:        {
      nickname: 'dhh',
      email:    'dhh@rails.com'
    },
    credentials: {
      token: token
    }
  )

  require 'webmock'

  module StubUser
    extend WebMock::API

    def self.stub_login(token)
      response = [
        {
          "login": "nil-inc",
        }
      ]

      stub_request(:get, "https://api.github.com/user/orgs")
        .with(
          headers: {
            "Authorization" => "token #{token}"
          }
        )
        .to_return(
          body:    response.to_json,
          status:  200,
          headers: {
            "Content-Type"        => "application/json; charset=utf-8",
            "Vary"                => "Accept, Authorization, Cookie, X-GitHub-OTP, Accept-Encoding",
            "X-GitHub-Media-Type" => "github.v3"
          }
        )
    end
  end

  StubUser.stub_login(token)
end
