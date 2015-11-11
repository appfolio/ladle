class StewardNotifier
  def initialize(stewards_map, repository_name, pull_request)
    @repository_name = repository_name
    @pull_request    = pull_request
    @stewards_map    = stewards_map
  end

  def notify
    notified_users = []
    @stewards_map.each do |github_username, stewards_files_paths|
      user = User.find_by_github_username(github_username)

      if user
        send_email(user, stewards_files_paths)
        notified_users << user
      end
    end
  ensure
    create_notification(notified_users)
  end

  private

  def send_email(user, stewards_files)
    UserMailer.notify(user: user, repository: @repository_name, pull_request: @pull_request, stewards_files: stewards_files).deliver_now
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
