class Repository < ActiveRecord::Base
  belongs_to :access_via, class_name: 'User'

  validates :name, presence: true
  validates :webhook_secret, presence: true
  validates :access_via, presence: true

  def access_token
    access_via.token
  end

  def compute_webhook_signature(data)
    'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), webhook_secret, data)
  end
end
