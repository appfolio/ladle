module Ladle
  class StewardNotifier
    def initialize(repository_name, pull_request)
      @repository_name = repository_name
      @pull_request    = pull_request
    end

    def notify(stewards_changes)
      notified_users = []
      stewards_changes.each do |github_username, changes_view|
        Array.wrap(github_username).each do |username|
          notify_user(notified_users, username, changes_view)
        end
      end
    ensure
      create_notification(notified_users)
    end

    private

    def notify_user(notified_users, github_username, changes_view)
      user = User.find_by_github_username(github_username)

      if user && !user_has_been_notified?(user)
        send_email(user, changes_view)
        notified_users << user
      end
    end

    def user_has_been_notified?(user)
      user.notifications.where(pull_request: @pull_request).exists?
    end

    def send_email(user, changes_view)
      UserMailer.notify(user: user, repository: @repository_name, pull_request: @pull_request, changes_view: changes_view).deliver_now
    end

    def create_notification(users)
      return if users.empty?

      ActiveRecord::Base.transaction do
        notification = Notification.create!(pull_request: @pull_request)
        users.each do |user|
          notification.notified_users << user
        end

        notification
      end
    end
  end
end
