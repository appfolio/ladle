require 'test_helper'
require 'ladle'

require 'ladle/pull_handler'
require 'ladle/steward_notifier'
require 'ladle/local_repository_client'

class LocalRepoTest < ActiveSupport::TestCase

  test 'the test' do
    user = create(:user, github_username: 'dtognazzini')
    pull_request = create(:pull_request, number: 1, html_url: 'https://github.com/bleh/test/pull/11')

    client = Ladle::LocalRepositoryClient.new('/Users/dtognazzini/src/appfolio/ladle-stage',
                                              base_ref: 'dbe4952c800c9d50fb61e68d883765d907995200',
                                              head_ref: '4a52ed41d75eefee84d48854d8932cb1053df35e')

    notifier = Ladle::StewardNotifier.new("ladle-stage", pull_request)

    pull_handler = Ladle::PullHandler.new(client, notifier)

    ActionMailer::Base.logger = ::Logger.new(STDOUT)
    pull_handler.handle(pull_request)
  end
end

