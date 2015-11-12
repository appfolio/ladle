require 'test_helper'
require 'pull_handler'

class PullHandlerTest < ActiveSupport::TestCase
  setup do
    user = create(:user)
    @repository = Repository.create!(name: 'xanderstrike/test', webhook_secret: 'whatever', access_via: user)
    @pull_request = create(:pull_request, repository: @repository, number: 30, html_url: 'www.test.com')
  end

  test 'does nothing when there are not stewards' do
    client = Octokit::Client.any_instance
    client.expects(:pull_request).with(@repository.name, @pull_request.number).returns(
      {
        head: {
          sha: '123432143412412342'
        }
      })

    client.expects(:pull_request_files).with(@repository.name, @pull_request.number).returns(
      [
        {filename: 'one.rb'},
        {filename: 'sub/marine.rb'},
      ])

    client.expects(:contents).with(@repository.name, path: '/sub/stewards.yml', ref: '123432143412412342').raises(Octokit::NotFound)
    client.expects(:contents).with(@repository.name, path: '/stewards.yml', ref: '123432143412412342').raises(Octokit::NotFound)

    logger_mock = mock
    logger_mock.expects(:info).with('No stewards found. Doing nothing.')
    Rails.stubs(:logger).returns(logger_mock)

    StewardNotifier.expects(:new).never

    PullHandler.new(@pull_request).handle
  end

  test 'notifies stewards' do
    client = Octokit::Client.any_instance
    client.expects(:pull_request).with(@repository.name, @pull_request.number).returns(
      {
        head: {
          sha: '123432143412412342'
        }
      })

    client.expects(:pull_request_files).with(@repository.name, @pull_request.number).returns(
      [
        {filename: 'one.rb'},
        {filename: 'sub/marine.rb'},
      ])

    stewards_file1 = <<-YAML
      stewards:
        - xanderstrike
        - fadsfadsfadsfadsf
    YAML
    stewards_file1_contents = Base64.encode64(stewards_file1)
    client.expects(:contents).with(@repository.name, path: '/sub/stewards.yml', ref: '123432143412412342').returns(content: stewards_file1_contents)

    stewards_file2 = <<-YAML
      stewards:
        - xanderstrike
        - bob
    YAML
    stewards_file2_contents = Base64.encode64(stewards_file2)

    client.expects(:contents).with(@repository.name, path: '/stewards.yml', ref: '123432143412412342').returns(content: stewards_file2_contents)

    mock_notifier = mock
    mock_notifier.expects(:notify)
    StewardNotifier.expects(:new)
      .with({
              'xanderstrike'      => ['/sub/stewards.yml', '/stewards.yml'],
              'fadsfadsfadsfadsf' => ['/sub/stewards.yml'],
              'bob'               => ['/stewards.yml']
            },
            @repository.name,
            @pull_request
      )
      .returns(mock_notifier)

    PullHandler.new(@pull_request).handle
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
