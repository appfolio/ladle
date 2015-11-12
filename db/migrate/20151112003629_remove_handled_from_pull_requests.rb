class RemoveHandledFromPullRequests < ActiveRecord::Migration
  def change
    remove_column :pull_requests, :handled, :boolean, default: false, null: false
  end
end
