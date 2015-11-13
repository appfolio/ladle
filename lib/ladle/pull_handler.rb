module Ladle
  class PullHandler
    def initialize(pull_request, notifier)
      @pull_request = pull_request
      @repository   = pull_request.repository

      @notifier = notifier
    end

    def handle
      client = Octokit::Client.new(access_token: @repository.access_token)

      pr_info = fetch_pr_info(client)

      changed_files = fetch_changed_files(client)

      stewards_registry = {}

      read_current_stewards(client, stewards_registry, changed_files.modified, pr_info.head_sha)
      read_old_stewards(client, stewards_registry, changed_files.modified_stewards_files, pr_info.base_sha)

      if stewards_registry.empty?
        Rails.logger.info('No stewards found. Doing nothing.')
      else
        Rails.logger.info("Found #{stewards_registry.size} stewards. Notifying.")
        @notifier.notify(stewards_registry)
      end
    end

    private

    PullRequestInfo = Struct.new(:head_sha, :base_sha)

    def fetch_pr_info(client)
      pr = client.pull_request(@repository.name, @pull_request.number)
      PullRequestInfo.new(pr[:head][:sha], pr[:base][:sha])
    end

    ChangedFiles = Struct.new(:modified, :modified_stewards_files)

    def fetch_changed_files(client)
      changed_files = ChangedFiles.new([], [])

      client.pull_request_files(@repository.name, @pull_request.number).each do |file|
        changed_files.modified << file[:filename]

        if file[:filename] =~ /stewards\.yml$/ && ( file[:status] == 'removed' || file[:status] == 'modified' )
          changed_files.modified_stewards_files << file[:filename]
        end
      end

      changed_files
    end

    def read_current_stewards(client, registry, files_changed_in_pull_request, pr_head)
      directories = directories_in_file_paths(files_changed_in_pull_request)
      directories.each do |directory|
        stewards_file_path = File.join(directory, 'stewards.yml')

        register_stewards(client, registry, stewards_file_path, pr_head)
      end
    end

    def read_old_stewards(client, registry, modified_stewards_files, parent_head)
      modified_stewards_files.each do |stewards_file_path|
        stewards_file_path = File.join("/", stewards_file_path)

        register_stewards(client, registry, stewards_file_path, parent_head)
      end
    end

    def register_stewards(client, registry, file_path, sha)
      contents = client.contents(@repository.name, path: file_path, ref: sha)[:content]
      contents = YAML.load(Base64.decode64(contents))

      contents['stewards'].each do |github_username|
        registry[github_username] ||= []
        registry[github_username] << file_path
      end
    rescue Octokit::NotFound
    end

    def directories_in_file_paths(file_paths)
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
end
