class Notification < ActiveRecord::Base
  belongs_to :pull_request
  validates :pull_request, presence: true
end
