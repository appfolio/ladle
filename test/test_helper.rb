ENV['RAILS_ENV'] ||= 'test'
require 'simplecov'
SimpleCov.start 'rails'
SimpleCov.minimum_coverage 100

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'vcr'
require 'mocha/mini_test'

require 'github_stubs'

class MiniTest::Test
  include FactoryGirl::Syntax::Methods
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr_cassettes'
  c.hook_into :webmock
end

module VCRHelpers
  def using_vcr
    # Builds a cassette with the format:
    #   name_of_file-name_of_test.yml
    cassette_name =  caller[0][%r{/.*\.}].split('/').last[0..-2] +
                     '-' + name
    VCR.use_cassette(cassette_name) do
      yield
    end
  end
end

class ActionController::TestCase
  include Devise::TestHelpers
end
