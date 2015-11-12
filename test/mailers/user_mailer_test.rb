require 'test_helper'

class UserMailerTest < ActionMailer::TestCase

  PullRequestLike = Struct.new(:html_url, :title, :body)

  test "notify - minimum" do
    user  = create(:user)
    email = UserMailer.notify(user:           user,
                              repository:     'XanderStrike/test',
                              pull_request: PullRequestLike.new(
                                'https://github.com/XanderStrike/test/pull/11',
                                nil,
                                nil
                              ),
                              stewards_files: ['/stewards.yml', '/bleh/stewards.yml']).deliver_now

    assert_not ActionMailer::Base.deliveries.empty?

    # Test the body of the sent email contains what we expect it to
    assert_equal ['no-reply@appfolio.com'], email.from
    assert_equal [user.email], email.to
    assert_equal '[XanderStrike/test] Ladle Alert: New Pull Request', email.subject
  end

  test "notify - full" do
    user  = create(:user)
    email = UserMailer.notify(user:           user,
                              repository:     'XanderStrike/test',
                              pull_request:   PullRequestLike.new(
                                'https://github.com/XanderStrike/test/pull/11',
                                'Hey ho!',
                                'These changes are luminous',
                              ),
                              stewards_files: ['/stewards.yml', '/bleh/stewards.yml']).deliver_now

    assert_not ActionMailer::Base.deliveries.empty?

    # Test the body of the sent email contains what we expect it to
    assert_equal ['no-reply@appfolio.com'], email.from
    assert_equal [user.email], email.to
    assert_equal '[XanderStrike/test] Ladle Alert: Hey ho!', email.subject
  end
end
