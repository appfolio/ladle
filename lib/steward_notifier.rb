class StewardNotifier
  def initialize(stewards, handler)
    @stewards = stewards
    @handler = handler
  end

  def notify
    email_stewards = @stewards.select { |s| s.include?('@') }
    github_stewards = @stewards - email_stewards
    notify_github(github_stewards, email_stewards)
    notify_emails(email_stewards)
  end

  private

  def notify_github(usernames, emails)
    usernames = usernames.uniq.map { |s| "@#{s}" }
    credentials = YAML.load(File.open("#{Rails.root}/config/github.yml"))
    client = Octokit::Client.new(access_token: credentials['access_token'])

    message = <<-STRING
Hey, sweet pull request you got here!

Here are some stewards who might want a look: #{usernames.join(' ')}. These emails were also notified #{emails.join(' ')}.

Keep being awesome.
STRING

    client.add_comment(@handler.repo, @handler.number, message)
  end

  def notify_emails(email_stewards)
    # sendgrid goes here?
  end
end
