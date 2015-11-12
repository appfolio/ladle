require 'steward_notifier'

class PullHandler
  def initialize(pull_request)
    @pull_request = pull_request
    @repository   = pull_request.repository
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
