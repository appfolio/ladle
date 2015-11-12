class RenamePullRequestsDescriptionToBody < ActiveRecord::Migration
  def change
    rename_column :pull_requests, :description, :body
  end
end
