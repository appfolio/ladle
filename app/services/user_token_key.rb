# frozen_string_literal: true

class UserTokenKey
  ATTR_ACCESSOR_KEY_SIZE = 32 # bytes

  def self.get
    @token_key ||= begin
      token_key = Rails.application.config_for(:secrets)["token_key"]
      raise "Set TOKEN_KEY env var" unless token_key
      raise "Token key must be 32 bytes" unless token_key.bytes.size == 32
      token_key
    end
  end
end
