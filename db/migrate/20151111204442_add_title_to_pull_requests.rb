class AddTitleToPullRequests < ActiveRecord::Migration
  def change
    add_column :pull_requests, :title, :string
  end
end
