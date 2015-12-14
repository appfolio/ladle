module Ladle
  module TestData
    extend FactoryGirl::Syntax::Methods

    def self.create_steward_changes_views
      {
        'app/stewards.yml'        => [Ladle::StewardChangesView.new(
                                        stewards_file: 'app/stewards.yml',
                                        changes:       [
                                                         build(:file_change, status: :removed, file: "app/removed_file.rb", deletions: 6),
                                                         build(:file_change, status: :modified, file: "app/modified_file.rb", deletions: 3, additions: 3),
                                                         build(:file_change, status: :added, file: "app/new_file.rb", additions: 6),
                                                       ]),
                                      Ladle::StewardChangesView.new(
                                        stewards_file: 'app/stewards.yml',
                                        changes:       [
                                                         build(:file_change, status: :modified, file: "app/blah.rb", deletions: 3, additions: 3),
                                                       ])],
        'lib/closet/stewards.yml' => [Ladle::StewardChangesView.new(
                                        stewards_file: 'lib/closet/stewards.yml',
                                        changes:       [
                                                         build(:file_change, status: :added, file: "lib/closet/top_shelf/new_file.rb", additions: 6),
                                                       ])],
      }
    end
  end
end
