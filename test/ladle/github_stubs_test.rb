require 'test_helper'

class GithubStubsTest < ActiveSupport::TestCase

  test 'stub_login stubs orgs api' do
    token = "token"
    GithubStubs.stub_login(token)
    github_client = Octokit::Client.new(access_token: token)

    organizations = github_client.orgs.map { |org| org[:login] }
    assert_equal ["nil-inc"], organizations
  end

  test 'stub_emails stubs emails api' do
    token = "token"
    GithubStubs.stub_emails(token)
    github_client = Octokit::Client.new(access_token: token)

    emails = github_client.emails.map do |email|
      {
        "email": email.email,
        "primary": email.primary,
        "verified": email.verified
      }
    end

    expected_emails = [
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

    assert_equal expected_emails, emails
  end
end
