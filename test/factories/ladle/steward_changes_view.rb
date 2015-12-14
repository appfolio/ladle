FactoryGirl.define do
  factory :steward_changes_view, class: "Ladle::StewardChangesView" do
    ref 'base'
    stewards_file 'stewards.yml'
    file_filter nil
    changes nil

    initialize_with do
      new(ref:           ref,
          stewards_file: stewards_file,
          file_filter:   file_filter,
          changes:       changes)
    end
  end
end
