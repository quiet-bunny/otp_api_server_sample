class User < ActiveRecord::Base
  belongs_to :application

  validates :user_id, uniqueness: {
    scope: :application_id
  },
  length: {
    in: 1..255
  }
  validate :validate_application

  def validate_application
    errors[:application_id] << "aaa" unless Application.where(id: application_id).exists?
  end

  def self.new_with(params)
    self.new(
      user_id: params["user_id"],
      secret: ROTP::Base32.random_base32
    )
  end

  def validate_key(params)
    if params["key"].present?
      validate_time_key(params["key"])
    elsif params["cached_key"].present?
      validate_cached_key(params["cached_key"])
    else
      raise InvalidKeyType
    end
  end

  def validate_time_key(key)
    totp = ROTP::TOTP.new(self.secret)
    timestamp = Time.now.to_i
    (timestamp - App.config["key_expire"] .. timestamp + App.config["key_expire"]).step(30).any? do |time|
      totp.at(time).to_s == key.to_s
    end
  end

  def validate_cached_key(key)
    return false if key.blank?
    result = App.cache.read(cache_key) == key.strip.tr("０-９", "0-9")
    App.cache.delete(cache_key) if result
    result
  end

  def generate_cached_key
    key = 6.times.inject("") do |s|
      s << (0..9).to_a.sample(1).first.to_s
    end
    App.cache.write(cache_key, key, expires_in: self.application.cached_key_expire)
    key
  end

  def cache_key
    ["cached_key", self.id]
  end

  class NotFound < StandardError; end
  class AddFailed < StandardError; end
  class InvalidKeyType < StandardError; end
end
