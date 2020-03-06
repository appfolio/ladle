module Ladle
  module TestData
    extend FactoryBot::Syntax::Methods

    def self.create_changes_view
      Ladle::ChangesView.new(
        {
          rules:   Ladle::StewardRules.new(ref:           'base',
                                           stewards_file: 'app/stewards.yml'),
          changes: [
                     build(:file_change, status: :removed, file: "app/removed_file.rb", deletions: 6),
                     build(:file_change, status: :modified, file: "app/modified_file.rb", deletions: 3, additions: 3),
                     build(:file_change, status: :added, file: "app/new_file.rb", additions: 6),
                   ]
        },
        {
          rules:   Ladle::StewardRules.new(ref:           'branch',
                                           stewards_file: 'app/stewards.yml'),
          changes: [
                     build(:file_change, status: :modified, file: "app/blah.rb", deletions: 3, additions: 3),
                   ]
        },
        {
          rules:   Ladle::StewardRules.new(ref:           'base',
                                           stewards_file: 'lib/closet/stewards.yml'),
          changes: [
                     build(:file_change, status: :added, file: "lib/closet/top_shelf/new_file.rb", additions: 6),
                   ]
        }
      )
    end

    def self.create_stewards_map
      {
        'xanderstrike' => create_changes_view,
        'counterstrike'=> create_changes_view,
        'boop'         => create_changes_view
      }
    end
  end
end
