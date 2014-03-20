class Application < ActiveRecord::Base
  has_many :users

  validates :name,
    uniqueness: true

  attr_accessor :secret

  def self.create_with(params)
    app = self.new(
      name: params["name"],
      key_expire: App.config["key_expire"],
      cached_key_expire: App.config["cached_key_expire"]
    )
    app.generate_secret
    app.save
    app
  end

  def self.auth_with_header!(str)
    auth = Hash[*str.scan(/(application_id|secret)="(.+?)"/).flatten] if str =~ /OtpApi /
    auth_with_hash!(auth)
  end

  def self.auth_with_hash!(hash)
    app = self.find(hash["application_id"])
    app.secret = hash["secret"]

    if app.valid_secret?
      app
    else
      raise AuthFailed
    end
  rescue ActiveRecord::RecordNotFound
    raise NotFound
  end

  def self.authorize!(params={})
    if params["auth"].present?
      auth_with_header!(params["auth"])
    elsif params["data"].has_key?("secret") && params.data.has_key?("application_id")
      auth_with_hash!(params["data"])
    elsif params.has_key?("secret") && params.has_key?("application_id")
      auth_with_hash!(params)
    else
      raise AuthFailed
    end
  end

  def generate_secret
    @secret = SecureRandom.base64
    self.encrypted_secret = Digest::SHA256.hexdigest(@secret)
  end

  def valid_secret?
    self.encrypted_secret == Digest::SHA256.hexdigest(self.secret)
  end

  def push_user!(params)
    user = User.new_with(params)
    if self.users << user
      user
    else
      raise ::User::AddFailed, user.errors.messages
    end
  end

  class AuthFailed < StandardError; end
  class NotFound < StandardError; end
end
