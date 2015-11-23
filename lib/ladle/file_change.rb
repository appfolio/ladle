module Ladle
  class FileChange
    STATUS_INITIALS = {
      removed: "D",
      modified: "M",
      added: "A"
    }
    attr_reader :status, :file, :additions, :deletions, :changes

    def initialize(status:, file:, additions:, deletions:, changes:)
      @status    = status
      @file      = Pathname.new(file)
      @additions = additions
      @deletions = deletions
      @changes   = changes

      raise ArgumentError, "Invalid status: '#{@status}'" unless STATUS_INITIALS.keys.include?(@status)
    end

    def changes_count
      case status
      when :removed
        @deletions
      when :added
        @additions
      when :modified
        @additions + @deletions + @changes
      end
    end

    def status_initial
      STATUS_INITIALS[status]
    end

    def ==(other)
      @status == other.status       &&
      @file == other.file           &&
      @additions == other.additions &&
      @deletions == other.deletions &&
      @changes == other.changes
    end

    def hash
      [@status, @file, @additions, @deletions, @changes].hash
    end

    alias eql? ==
  end
end
