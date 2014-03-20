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
    if params["time_key"].present?
      validate_time_key(params["time_key"])
    elsif params["cached_key"].present?
      validate_cached_key(params["cached_key"])
    else
      raise InvalidKeyType
    end
  end

  def validate_time_key(key)
  end

  def validate_cached_key(key)
    cached_key = App.cache.read(cache_key)
    App.cache.delete(cache_key)
    cached_key == key.strip.tr("０-９", "0-9")
  end

  def generate_cached_key
    key = 6.times.inject("") do |s|
      s << (0..9).to_a.sample(1).first.to_s
    end
    App.cache.write(self.cache_key, key, expires_in: self.application.cached_key_expire)
    key
  end

  def cache_key
    [self.application_id, self.user_id]
  end

  class NotFound < StandardError; end
  class AddFailed < StandardError; end
  class InvalidKeyType < StandardError; end
end
