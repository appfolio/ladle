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
      @file = file

      raise ArgumentError, "Invalid status: '#{@status}'" unless STATUS_INITIALS.keys.include?(@status)
    end

    def status_initial
      STATUS_INITIALS[status]
    end
  end
end
