class AddIvToUsers < ActiveRecord::Migration[5.0]
  def up
    rename_column :users, :encrypted_token, :encrypted_token_old

    add_column :users, :encrypted_token, :string
    add_column :users, :encrypted_token_iv, :string
  end

  def down
    remove_column :users, :encrypted_token, :string
    remove_column :users, :encrypted_token_iv, :string

    rename_column :users, :encrypted_token_old, :encrypted_token
  end
end
