import Config

# Configure logging for test environment
config :logger, level: :error

# Test-specific configuration for Cash Register
config :cash_register,
  # Don't log successful transactions in tests (reduces noise)
  log_sample_rate: 0.0
