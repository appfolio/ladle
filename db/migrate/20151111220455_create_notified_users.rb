class CreateNotifiedUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :notified_users do |t|
      t.belongs_to :notification, index: true
      t.belongs_to :user, index: true
    end
  end
end
