require 'steward_notifier'

class PullHandler
  attr_reader :repository, :number, :html_url

  def initialize(repository:, pull_request_data:)
    @repository        = repository

    @pull_request = PullRequest.find_or_create_by(
      repository:  @repository,
      number:      pull_request_data[:number],
      title:       pull_request_data[:title],
      html_url:    pull_request_data[:html_url],
      description: pull_request_data[:description])
  end

  def handle
    client = Octokit::Client.new(access_token: @repository.access_token)

    pr = client.pull_request(@repository.name, @pull_request.number)
    head_sha = pr[:head][:sha]

    filenames = client.pull_request_files(@repository.name, @pull_request.number).map do |file|
      file[:filename]
    end

    directories = filenames.map do |filename|
      filename.sub(%r{(\/[^\/]+|[^\/]+)$}, '')
    end

    directories = directories.uniq

    stewards_map = {}
    directories.each do |directory|
      stewards_file_path = File.join('/', directory, 'stewards.yml')
      begin
        contents = client.contents(@repository.name, path: stewards_file_path, ref: head_sha)[:content]
        contents = YAML.load(Base64.decode64(contents))

        contents['stewards'].each do |github_username|
          stewards_map[github_username] ||= []
          stewards_map[github_username] << stewards_file_path
        end
      rescue Octokit::NotFound
        next
      end
    end

    if stewards_map.empty?
      Rails.logger.info('No stewards found. Doing nothing.')
    else
      Rails.logger.info("Found #{stewards_map.size} stewards. Notifying.")
      StewardNotifier.new(stewards_map, @repository.name, @pull_request).notify
    end
  end
end
