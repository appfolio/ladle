module Ladle
  class ChangedFiles
    attr_reader :modified_stewards_files

    class Directory
      attr_reader :name, :changes

      def initialize(name, changes = nil)
        @name    = name
        @changes = changes || []
      end

      def add_change(change)
        Directory.new(@name, @changes + [change])
      end
    end

    def initialize
      @modified_stewards_files = []
      @directories = {}
    end

    def file_changes_in(directory_path)
      directory_path = normalize_directory_path(directory_path)

      file_changes = []
      @directories.each_value do |directory|
        changed_directory_path = normalize_directory_path(directory.name)

        if changed_directory_path.start_with?(directory_path)
          file_changes.concat(directory.changes)
        end
      end
      file_changes
    end

    def directories
      @directories.keys.sort.reverse
    end

    def add_file_change(file_change)
      directory_name = file_change.file.dirname

      new_directories = {}.merge(@directories)

      new_directories[directory_name] ||= Directory.new(directory_name)
      new_directories[directory_name] = new_directories[directory_name].add_change(file_change)

      modified_stewards_files = [].concat(@modified_stewards_files)

      if file_change.file.to_s =~ /stewards\.yml$/ && file_change.status != :removed
        modified_stewards_files << file_change.file
      end

      # add all other directories for this file
      file_change.file.ascend do |file|
        new_directories[file.dirname] = new_directories[file.dirname] || Directory.new(file.dirname)
      end

      changed_files = ChangedFiles.allocate
      changed_files.initialize_with_new_file_change(new_directories, modified_stewards_files)
      changed_files
    end

    def ==(other)
      @modified_stewards_files == other.modified_stewards_files && directories == other.directories
    end

    alias eql? ==

    protected

    def initialize_with_new_file_change(directories, modified_stewards_files)
      @directories = directories
      @modified_stewards_files = modified_stewards_files
    end

    private

    def normalize_directory_path(path)
      path = "/#{path}/"
      path = '/' if ['//', './', '/./', '/.//'].include?(path)
      path
    end
  end
end
