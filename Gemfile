source 'https://rubygems.org'
ruby '2.6.3'

gem 'rails_12factor', group: :production

gem 'rails', '~> 6.1.6', '>= 6.1.6.1'
# Use sqlite3 as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# Adding direct dependency to move to secure version
gem 'json', '~> 2.3'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 1.1.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'attr_encrypted', '~> 3.0'

gem 'puma', ">= 4.3.5"

gem 'devise'
gem 'devise-bootstrap-views'
gem 'omniauth-github'

gem 'octokit', '~> 4.1'

gem 'simple_form', '~> 5.0'
gem 'factory_bot_rails', '~> 4.0'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'webmock', require: false
end

group :test do
  gem 'mocha'
  gem 'minitest', '5.10.3'
  gem 'webmock'
  gem 'coveralls', require: false
  gem 'rugged', require: false
  gem 'hashdiff', '0.2.2'
end
