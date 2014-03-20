require "sinatra/base"
require "sinatra/contrib"
require "active_support"
require "sinatra/activerecord"
require "digest"
require "yaml"
require "rotp"
Dir.glob("./app/*/*.rb").each{|r| require r}

class OtpApi < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  register Sinatra::Contrib

  set :database, {}
  set(:request_method){|v| condition{request.request_method == v.to_s.upcase} }
  set :raise_errors, false
  set :show_exceptions, :after_handler

  def self.cache
    @@cache ||= ActiveSupport::Cache.const_get(config["cache_store"]).new
  end

  def self.config
    @@settings ||= YAML.load_file("config/config.yml")[Sinatra::Application.environment.to_s]
  end

  get "/" do
    "Hello"
  end

  namespace "/api" do
    before request_method: :post do
      @data = Rack::Utils.parse_nested_query(request.body.read)
    end

    before do
      @app = Application.authorize!(params.merge({
        "data" => @data || {},
        "auth" => request.env["HTTP_AUTHORIZATION"]
      }))
    end

    namespace "/users" do
      def user
        @user ||= @app.users.find_by(user_id: params["user_id"])
      end

      get "/:user_id" do
        begin
          json user
        rescue ::ActiveRecord::RecordNotFound
          raise ::User::NotFound
        end
      end

      post "" do
        user = @app.push_user!(@data)
        json user
      end

      get "/:user_id/key" do
        json user.generate_cached_key
      end

      post "/:user_id/key" do
        json user.validate_key(@data)
      end
    end

    error ::Application::AuthFailed do
      result = {status: "error", error: "ERR_APP_AUTH_FAILED"}
      status 400
      json result
    end

    error ::Application::NotFound do
      result = {status: "error", error: "ERR_APP_NOT_FOUND"}
      status 404
      json result
    end

    error ::User::NotFound do
      result = {status: "error", error: "ERR_USER_NOT_FOUND"}
      status 404
      json result
    end

    error ::User::AddFailed do
      result = {status: "error", error: "ERR_USER_ADD_FAILED", messages: env['sinatra.error'].message}
      status 400
      json result
    end
  end
end

App = OtpApi
