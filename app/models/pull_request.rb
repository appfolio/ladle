class PullRequest < ActiveRecord::Base
  validates :number, presence: true
  validates :repo, presence: true
end
