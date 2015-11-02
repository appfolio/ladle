class StewardNotifier
  def initialize(stewards_map, pull_request_url)
    @stewards_map     = stewards_map
    @pull_request_url = pull_request_url
  end

  def notify
    @stewards_map.each do |github_username, stewards_files_paths|
      user = User.find_by_github_username(github_username)

      if user
        send_email(user.email, stewards_files_paths)
      end
    end
  end

  private

  def send_email(email, stewards_files)
    UserMailer.notify(email: email, pull_request_url: @pull_request_url, stewards_files: stewards_files).deliver_now
  end
end
