FactoryGirl.define do
  factory :changes_view, class: "Ladle::ChangesView" do

    initialize_with do
      view = new
      attributes[:changes].each do |rules_and_changes|
        view.add_changes(rules_and_changes[:rules], rules_and_changes[:changes])
      end

      view
    end
  end
end
