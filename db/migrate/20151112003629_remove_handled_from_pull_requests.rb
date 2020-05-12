class RemoveHandledFromPullRequests < ActiveRecord::Migration[4.2]
  def change
    remove_column :pull_requests, :handled, :boolean, default: false, null: false
  end
end
