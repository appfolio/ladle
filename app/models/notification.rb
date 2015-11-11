class Notification < ActiveRecord::Base
  belongs_to :pull_request
  validates :pull_request, presence: true

  has_and_belongs_to_many :notified_users, join_table: :notified_users, class_name: 'User'
end
