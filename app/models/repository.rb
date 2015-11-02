class Repository < ActiveRecord::Base
  validates :name, presence: true
  validates :webhook_secret, presence: true
  validates :access_token, presence: true
end
