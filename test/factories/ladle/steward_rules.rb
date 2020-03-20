FactoryBot.define do
  factory :steward_rules, class: "Ladle::StewardRules" do
    ref { 'base' }
    stewards_file { 'stewards.yml' }
    file_filter { nil }

    initialize_with do
      new(ref:           ref,
          stewards_file: stewards_file,
          file_filter:   file_filter)
    end
  end
end
