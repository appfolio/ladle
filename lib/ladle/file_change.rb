module Ladle
  class FileChange
    STATUS_INITIALS = {
      removed:  "D",
      modified: "M",
      added:    "A",
      renamed:  "R",
      copied:   "C",
    }
    attr_reader :status, :file, :additions, :deletions

    def initialize(status:, file:, additions:, deletions:)
      @status    = status
      @file      = Pathname.new(file)
      @additions = additions
      @deletions = deletions

      raise ArgumentError, "Invalid status: '#{@status}'" unless STATUS_INITIALS.keys.include?(@status)
    end

    def changes_count
      case status
      when :removed
        @deletions
      when :added
        @additions
      when :modified, :renamed, :copied
        @additions + @deletions
      end
    end

    def status_initial
      STATUS_INITIALS[status]
    end

    def ==(other)
      @status == other.status       &&
      @file == other.file           &&
      @additions == other.additions &&
      @deletions == other.deletions
    end

    def hash
      [@status, @file, @additions, @deletions].hash
    end

    alias eql? ==
  end
end
