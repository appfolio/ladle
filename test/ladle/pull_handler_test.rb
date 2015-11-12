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

  test 'notifies stewards' do
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

  test "directories_to_search" do
    expected_directories = [
      "/some/really/deep",
      "/some/really",
      "/some",
      "/other",
      "/",
    ]

    handler     = PullHandler.new(@pull_request)
    directories = handler.send(:directories_to_search,
                               [
                                 "some/really/deep/file.rb",
                                 "other/file.rb",
                               ])

    assert_equal expected_directories, directories
  end
end
