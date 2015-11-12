require 'delegate'

class NotificationsController < AuthenticatedController

  class NotificationPresenter < SimpleDelegator
    def link
      pull_request.html_url
    end

    def title
      "[#{pull_request.repository.name}] #{pull_request.title}"
    end
  end

  def index
    @notifications = current_user.notifications.order('created_at DESC').map do |notification|
      NotificationPresenter.new(notification)
    end
  end
end
