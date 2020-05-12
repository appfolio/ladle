class EncryptUsersTokens < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :encrypted_token, :string
    remove_column :users, :token, :string
  end
end
