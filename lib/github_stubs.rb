require 'webmock'

module GithubStubs
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

  def self.stub_emails(token)
    response = [
      {
        "email": "dhh@rails.com",
        "primary": true,
        "verified": true
      },
      {
        "email": "dhh@internet.com",
        "primary": false,
        "verified": true
      },
      {
        "email": "dhh@users.noreply.github.com",
        "primary": false,
        "verified": true
      }
    ]

    stub_request(:get, "https://api.github.com/user/emails")
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
          "X-GitHub-Media-Type" => "github.v3",
        }
      )
  end
end
