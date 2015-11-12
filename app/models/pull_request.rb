class PullRequest < ActiveRecord::Base
  belongs_to :repository

  validates :number, presence: true
  validates :repository, presence: true
end
