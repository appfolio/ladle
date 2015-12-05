# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  include FactoryGirl::Syntax::Methods

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
                      steward_changes_views: create_steward_changes_views)
  end

  def notify_without_description
    UserMailer.notify(user:           UserLike.new('someguy@someplace.com', 'dhh'),
                      repository:     'rails/rails',
                      pull_request:   PullRequestLike.new(
                        'https://github.com/rails/rails/pulls/1',
                        'Initial commit',
                        nil
                      ),
                      steward_changes_views: create_steward_changes_views)

  end

  private

  def create_steward_changes_views
    {
      'app/stewards.yml'        => Ladle::StewardChangesView.new(
        stewards_file: 'app/stewards.yml',
        changes:       [
                         build(:file_change, status: :removed, file: "app/removed_file.rb", deletions: 6),
                         build(:file_change, status: :modified, file: "app/modified_file.rb", deletions: 3, additions: 3),
                         build(:file_change, status: :added, file: "app/new_file.rb", additions: 6),
                       ]),
      'lib/closet/stewards.yml' => Ladle::StewardChangesView.new(
        stewards_file: 'lib/closet/stewards.yml',
        changes:       [
                         build(:file_change, status: :added, file: "lib/closet/top_shelf/new_file.rb", additions: 6),
                       ]),
    }
  end
end
