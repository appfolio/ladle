class EncryptUsersTokens < ActiveRecord::Migration
  def change
    add_column :users, :encrypted_token, :string
    remove_column :users, :token, :string
  end
end
