# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  UserLike = Struct.new(:email, :github_username)
  PullRequestLike = Struct.new(:html_url, :title, :body)

  def notify
    UserMailer.notify(user:           UserLike.new('someguy@someplace.com', 'dhh'),
                      repository:     'rails/rails',
                      pull_request:   PullRequestLike.new(
                        'https://github.com/rails/rails/pulls/1',
                        'Initial commit',
                        "We made these changes because things needed to be changed and we noticed and we had the means to make the changes, so we did."
                      ),
                      steward_change_sets: create_steward_change_sets)
  end

  def notify_without_description
    UserMailer.notify(user:           UserLike.new('someguy@someplace.com', 'dhh'),
                      repository:     'rails/rails',
                      pull_request:   PullRequestLike.new(
                        'https://github.com/rails/rails/pulls/1',
                        'Initial commit',
                        nil
                      ),
                      steward_change_sets: create_steward_change_sets)

  end

  private

  def create_steward_change_sets
    [
      Ladle::StewardsFileChangeSet.new('app/stewards.yml',
                                [
                                  Ladle::FileChange.new(:removed, "app/removed_file.rb"),
                                  Ladle::FileChange.new(:modified, "app/modified_file.rb"),
                                  Ladle::FileChange.new(:added, "app/new_file.rb"),
                                ]),
      Ladle::StewardsFileChangeSet.new('lib/closet/stewards.yml',
                                [
                                  Ladle::FileChange.new(:added, "lib/closet/top_shelf/new_file.rb"),
                                ]),
    ]
  end
end
