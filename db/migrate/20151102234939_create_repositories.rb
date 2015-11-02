class CreateRepositories < ActiveRecord::Migration
  def change
    create_table :repositories do |t|
      t.string :name, null: false
      t.string :webhook_secret, null: false
      t.string :access_token, null: false

      t.timestamps null: false
    end

    add_index :repositories, :name, unique: true
  end
end
