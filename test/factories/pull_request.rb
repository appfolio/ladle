FactoryGirl.define do
  sequence :number_sequence do |n|
    n.to_s
  end

  factory :pull_request do
    number { generate(:number_sequence) }
    repository { create(:repository) }
  end
end
