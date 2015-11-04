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

  require 'github_stubs'

  GithubStubs.stub_login(token)
  GithubStubs.stub_emails(token)
end
