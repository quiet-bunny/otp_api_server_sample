namespace :otp_api do
  namespace :application do
    desc "create application"
    task :create, [:name] do |t, args|
      app = Application.create_with(args)
      STDOUT.puts "ID: #{app.id}\nSECRET: #{app.secret}"
    end
  end
end
