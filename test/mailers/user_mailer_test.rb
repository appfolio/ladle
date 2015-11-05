require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "notify" do
    email = UserMailer.notify(email:            'some_dev@some_place.com',
                              pull_request_url: 'https://github.com/XanderStrike/test/pull/11',
                              stewards_files:   ['/stewards.yml', '/bleh/stewards.yml']).deliver_now

    assert_not ActionMailer::Base.deliveries.empty?

    # Test the body of the sent email contains what we expect it to
    assert_equal ['no-reply@appfolio.com'], email.from
    assert_equal ['some_dev@some_place.com'], email.to
    assert_equal 'Ladle: New PR', email.subject
  end
end
