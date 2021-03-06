class CreateNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :notifications do |t|
      t.integer :pull_request_id, null: false
      t.timestamps null: false
    end

    add_foreign_key :notifications, :pull_requests
  end
end
