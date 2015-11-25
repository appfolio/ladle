require 'delegate'

class UserMailer < ApplicationMailer
  default from: 'Appfolio Ladle <no-reply@appfolio.com>'

  class PullRequestPresenter < SimpleDelegator
    def title
      super || "New Pull Request"
    end
  end

  def notify(user:, repository:, pull_request:, steward_changes_views:)
    @pull_request = PullRequestPresenter.new(pull_request)
    @steward_changes_views = steward_changes_views
    @user = user

    mail(to:      user.email,
         subject: "[#{repository}] Ladle Alert: #{@pull_request.title}")
  end
end
