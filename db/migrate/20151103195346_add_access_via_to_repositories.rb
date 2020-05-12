class AddAccessViaToRepositories < ActiveRecord::Migration[4.2]
  def change
    remove_column  :repositories, :access_token, :string, null: false

    add_column :repositories, :access_via_id, :integer, null: false

    add_foreign_key :repositories, :users, column: :access_via_id, primary_key: :id
  end
end
