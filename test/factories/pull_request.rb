FactoryBot.define do
  sequence :number_sequence do |n|
    n.to_s
  end

  factory :pull_request do
    title { "Change up the World War Z."}
    number { generate(:number_sequence) }
    repository { create(:repository) }
  end
end
