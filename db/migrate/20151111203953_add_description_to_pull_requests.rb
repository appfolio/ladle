class AddDescriptionToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :description, :string
  end
end
