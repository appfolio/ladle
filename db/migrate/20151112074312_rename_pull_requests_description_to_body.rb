class RenamePullRequestsDescriptionToBody < ActiveRecord::Migration[4.2]
  def change
    rename_column :pull_requests, :description, :body
  end
end
