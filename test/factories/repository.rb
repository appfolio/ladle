FactoryBot.define do
  sequence :name_sequence do |n|
    "org/repo#{n}"
  end

  factory :repository do
    name { generate(:name_sequence) }
    webhook_secret "1ea7ca751ea7ca751ea7ca751ea7ca75"
    access_via { create(:user) }
  end
end
