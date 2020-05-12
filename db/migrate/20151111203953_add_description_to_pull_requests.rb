class AddDescriptionToPullRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :pull_requests, :description, :string
  end
end
