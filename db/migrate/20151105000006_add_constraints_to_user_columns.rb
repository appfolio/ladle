class AddConstraintsToUserColumns < ActiveRecord::Migration[4.2]
  def change
    change_column_null :users, :provider, null: false
    change_column_null :users, :uid, null: false
    change_column_null :users, :token, null: false
    change_column_null :users, :github_username, null: false
  end
end
