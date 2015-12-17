module Ladle
  extend ActiveSupport::Autoload

  autoload :FileChange
  autoload :ChangesView
  autoload :StewardRules
end

require 'ladle/exceptions'
