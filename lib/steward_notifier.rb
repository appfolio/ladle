class StewardNotifier
  def initialize(stewards, handler)
    @stewards = stewards
    @handler = handler
  end

  def notify
    @stewards.each do |github_username|
      user = User.find_by_github_username(github_username)
      next unless user
      send_email(user.email)
    end
  end

  private

  def send_email(email)
    UserMailer.notify(email, @handler.html_url).deliver_now
  end
end
