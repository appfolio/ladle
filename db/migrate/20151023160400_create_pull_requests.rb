class CreatePullRequests < ActiveRecord::Migration
  def change
    create_table :pull_requests do |t|
      t.string :repo, null: false
      t.integer :number, null: false
      t.string :html_url
      t.boolean :handled, null: false, default: false

      t.timestamps null: false
    end
  end
end
