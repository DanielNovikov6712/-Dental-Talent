# Load the onboarding module configuration (config/onboarding.yml) and expose it
# as Rails.application.config.onboarding.
Rails.application.configure do
  config.onboarding = config_for(:onboarding)
end
