require 'test_helper'
require 'pull_handler'

class PullHandlerTest < ActiveSupport::TestCase
  include VCRHelpers

  setup do
    user = create(:user)
    @repository = Repository.create!(name: 'xanderstrike/test', webhook_secret: 'whatever', access_via: user)
    @pull_request = create(:pull_request, repository: @repository, number: 30, html_url: 'www.test.com')
  end

  test 'does nothing when there are not stewards' do
    using_vcr do
      PullHandler.new(@pull_request).handle
    end
  end

  test 'creates a pull request object if it does not already exist' do
    mock_notifier = mock
    mock_notifier.expects(:notify)
    StewardNotifier.expects(:new)
      .with({'xanderstrike'                   => ['/stewards.yml'],
             'fadsfadsfadsfadsf'              => ['/stewards.yml'],
             'alexander.standke@appfolio.com' => ['/stewards.yml'],
             'xanderstrike@gmail.com'         => ['/stewards.yml']},
            @repository.name,
            @pull_request
      )
      .returns(mock_notifier)

    using_vcr do
      PullHandler.new(@pull_request).handle
    end
  end
end
