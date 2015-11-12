class CreateNotifiedUsers < ActiveRecord::Migration
  def change
    create_table :notified_users do |t|
      t.belongs_to :notification, index: true
      t.belongs_to :user, index: true
    end
  end
end
