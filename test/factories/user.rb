FactoryGirl.define do
  sequence :dhh_email do |n|
    "dhh#{n}@rails.com"
  end

  sequence :dhh_github_username do |n|
    "dhh#{n}"
  end

  factory :user do
    email { generate(:dhh_email) }
    password "railsrules"
    token "1ea7ca751ea7ca751ea7ca751ea7ca75"
    github_username { generate(:dhh_github_username) }
  end
end
