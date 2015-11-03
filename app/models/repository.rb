class Repository < ActiveRecord::Base
  validates :name, presence: true
  validates :webhook_secret, presence: true
  validates :access_token, presence: true

  def compute_webhook_signature(data)
    'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), webhook_secret, data)
  end
end
