class AddGithubUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :github_username, :string
    add_index :users, :github_username, unique: true
  end
end
