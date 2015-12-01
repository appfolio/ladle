module Ladle
  extend ActiveSupport::Autoload

  autoload :FileChange
  autoload :StewardChangesView
end

require 'ladle/exceptions'
