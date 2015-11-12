require 'steward_notifier'

class PullHandler
  def initialize(pull_request, notifier)
    @pull_request = pull_request
    @repository   = pull_request.repository

    @notifier = notifier
  end

  def handle
    client = Octokit::Client.new(access_token: @repository.access_token)

    pr = client.pull_request(@repository.name, @pull_request.number)
    head_sha = pr[:head][:sha]
    parent_head = pr[:base][:sha]

    files_changed = []
    removed_stewards_files = []
    client.pull_request_files(@repository.name, @pull_request.number).each do |file|
      files_changed << file[:filename]

      if file[:status] == 'removed' && file[:filename] =~ /stewards\.yml$/
        removed_stewards_files << file[:filename]
      end
    end

    directories = directories_to_search(files_changed)

    stewards_map = {}
    directories.each do |directory|
      stewards_file_path = File.join(directory, 'stewards.yml')

      parse_stewards_file(client, stewards_file_path, head_sha, stewards_map)
    end

    removed_stewards_files.each do |stewards_file_path|
      stewards_file_path = "/#{stewards_file_path}"
      parse_stewards_file(client, stewards_file_path, parent_head, stewards_map)
    end

    if stewards_map.empty?
      Rails.logger.info('No stewards found. Doing nothing.')
    else
      Rails.logger.info("Found #{stewards_map.size} stewards. Notifying.")
      @notifier.notify(stewards_map)
    end
  end

  private

  def parse_stewards_file(client, file_path, sha, stewards_map)
    contents = client.contents(@repository.name, path: file_path, ref: sha)[:content]
    contents = YAML.load(Base64.decode64(contents))

    contents['stewards'].each do |github_username|
      stewards_map[github_username] ||= []
      stewards_map[github_username] << file_path
    end

  rescue Octokit::NotFound
  end

  def directories_to_search(file_paths)
    directories = []
    file_paths.each do |path|
      path = Pathname.new("/#{path}")
      path = path.dirname
      path.ascend do |path_parent|
        directories << path_parent.to_s
      end
    end

    directories.uniq.sort.reverse
  end
end
