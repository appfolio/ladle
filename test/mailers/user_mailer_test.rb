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
                              stewards_file_map: create_steward_changes_views).deliver_now

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
                              stewards_file_map: create_steward_changes_views).deliver_now

    assert_not ActionMailer::Base.deliveries.empty?

    # Test the body of the sent email contains what we expect it to
    assert_equal ['no-reply@appfolio.com'], email.from
    assert_equal [user.email], email.to
    assert_equal '[XanderStrike/test] Ladle Alert: Hey ho!', email.subject
  end

  private

  def create_steward_changes_views
    {
      'app/stewards.yml'        => [Ladle::StewardChangesView.new(
                                      stewards_file: 'app/stewards.yml',
                                      changes:       [
                                                       build(:file_change, status: :removed, file: "app/removed_file.rb", deletions: 6),
                                                       build(:file_change, status: :modified, file: "app/modified_file.rb", deletions: 3, additions: 3),
                                                       build(:file_change, status: :added, file: "app/new_file.rb", additions: 6),
                                                     ])],
      'lib/closet/stewards.yml' => [Ladle::StewardChangesView.new(
                                      stewards_file: 'lib/closet/stewards.yml',
                                      changes:       [
                                                       build(:file_change, status: :added, file: "lib/closet/top_shelf/new_file.rb", additions: 6),
                                                     ])],
    }
  end
end
