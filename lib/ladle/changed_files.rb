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

    def initialize(*file_changes)
      @modified_stewards_files = []
      @directories = {}

      file_changes.each do |file_change|
        add_file_change_internal(file_change)
      end
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
      new_instance = self.dup
      new_instance.add_file_change_internal(file_change)
      new_instance
    end

    def ==(other)
      @modified_stewards_files == other.modified_stewards_files && directories == other.directories
    end

    alias eql? ==

    protected

    def directories_attribute
      @directories
    end

    def add_file_change_internal(file_change)
      directory_name = file_change.file.dirname

      @directories[directory_name] ||= Directory.new(directory_name)
      @directories[directory_name] = @directories[directory_name].add_change(file_change)

      if file_change.file.to_s =~ /stewards\.yml$/ && file_change.status != :removed
        @modified_stewards_files << file_change.file
      end

      # add all other directories for this file
      file_change.file.ascend do |file|
        @directories[file.dirname] ||= Directory.new(file.dirname)
      end
    end

    private

    def initialize_copy(other)
      @modified_stewards_files = other.modified_stewards_files.dup
      @directories = other.directories_attribute.dup
    end

    def normalize_directory_path(path)
      path = "/#{path}/"
      path = '/' if ['//', './', '/./', '/.//'].include?(path)
      path
    end
  end
end
