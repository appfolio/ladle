Rails.application.github_secret_token = Rails.env.production? ? ENV['SECRET_TOKEN'] : 'whatever'
Rails.application.github_access_token = ENV['GH_ACCESS_TOKEN']
