FactoryGirl.define do
  factory :file_change, class: "Ladle::FileChange" do
    status { :modified }
    file   { "bob/loblaw/law.blog" }

    initialize_with do
      new(status, file)
    end
  end
end
