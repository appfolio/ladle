# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  UserLike = Struct.new(:email, :github_username)
  PullRequestLike = Struct.new(:html_url, :title, :description)

  def notify
    UserMailer.notify(user:           UserLike.new('someguy@someplace.com', 'dhh'),
                      repository:     'rails/rails',
                      pull_request:   PullRequestLike.new(
                        'https://github.com/rails/rails/pulls/1',
                        'Initial commit',
                        "We made these changes because things needed to be changed and we noticed and we had the means to make the changes, so we did."
                      ),
                      stewards_files: ['app/stewards.yml', 'lib/closet/stewards.yml'])
  end

  def notify_without_description
    UserMailer.notify(user:           UserLike.new('someguy@someplace.com', 'dhh'),
                      repository:     'rails/rails',
                      pull_request:   PullRequestLike.new(
                        'https://github.com/rails/rails/pulls/1',
                        'Initial commit',
                        nil
                      ),
                      stewards_files: ['app/stewards.yml', 'lib/closet/stewards.yml'])
  end
end
