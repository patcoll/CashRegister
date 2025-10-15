import Config

# Configuration for Cash Register application

config :cash_register,
  # Sample rate for logging successful transactions (1.0 = 100%, 0.01 = 1%)
  # Reduce this in production to control log volume
  log_sample_rate: 1.0

config :logger, :default_formatter,
  metadata: :all

# Import environment-specific config
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
