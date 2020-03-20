FactoryBot.define do
  factory :file_change, class: "Ladle::FileChange" do
    additions { 0 }
    deletions { 0 }
    status    { :modified }
    file      { "bob/loblaw/law.blog" }

    initialize_with do
      new(status:    status,
          file:      file,
          additions: additions,
          deletions: deletions)
    end
  end
end
