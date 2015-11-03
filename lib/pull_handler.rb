require 'steward_notifier'

class PullHandler
  attr_reader :repository, :number, :html_url

  def initialize(repository:, number:, html_url:)
    @repository = repository
    @number = number
    @html_url = html_url
  end

  def handle
    return Rails.logger.info('Pull already handled, skipping.') if already_handled?

    client = Octokit::Client.new(access_token: @repository.access_token)

    pr = client.pull_request(@repository.name, @number)
    head_sha = pr[:head][:sha]

    filenames = client.pull_request_files(@repository.name, @number).map do |file|
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
      StewardNotifier.new(stewards_map, @html_url).notify
      @pr.update_attributes!(handled: true)
    end
  end

  def already_handled?
    @pr = PullRequest.find_or_create_by(repo: @repository.name, number: @number, html_url: @html_url)
    @pr.handled?
  end
end
