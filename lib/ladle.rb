module Ladle
  extend ActiveSupport::Autoload
  autoload :FileChange

  StewardsFileChangeSet = Struct.new(:stewards_file, :change_set)
end
