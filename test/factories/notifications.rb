FactoryBot.define do
  factory :notification do
    pull_request { create(:pull_request) }
  end
end
