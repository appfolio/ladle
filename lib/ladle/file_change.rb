module Ladle
  class FileChange
    STATUS_INITIALS = {
      removed: "D",
      modified: "M",
      added: "A"
    }
    attr_reader :status, :file

    def initialize(status, file)
      @status = status
      @file = Pathname.new(file)

      raise ArgumentError, "Invalid status: '#{@status}'" unless STATUS_INITIALS.keys.include?(@status)
    end

    def status_initial
      STATUS_INITIALS[status]
    end

    def ==(other)
      @status == other.status && @file == other.file
    end

    def hash
      [@status, @file].hash
    end

    alias eql? ==
  end
end
