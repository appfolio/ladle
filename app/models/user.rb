class User < ActiveRecord::Base
  devise :database_authenticatable,
         :rememberable, :trackable, :validatable

  devise :omniauthable, :omniauth_providers => [:github]

  has_and_belongs_to_many :notifications, join_table: :notified_users

  validates :github_username, presence: true, uniqueness: true
  validates :uid, presence: true

  attr_encrypted :token, key: ->(_) { UserTokenKey.get }
  attr_encrypted :token_old, key: 'hello', algorithm: 'aes-256-cbc', mode: :single_iv_and_salt, insecure_mode: true

  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.github_username = auth.info.nickname
      user.email = auth.info.email
      user.token = auth.credentials.token
      user.password = Devise.friendly_token[0,20]
    end

    token = auth.credentials.token

    if token != user.token
      user.update_attributes!(token: token)
    end

    user
  end
end
