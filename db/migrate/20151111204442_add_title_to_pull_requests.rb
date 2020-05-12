class AddTitleToPullRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :pull_requests, :title, :string
  end
end
