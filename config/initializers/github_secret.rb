if Rails.env.production?
  Rails.application.github_secret_token = ENV['SECRET_TOKEN']
else
  Rails.application.github_secret_token = "whatever"
end
