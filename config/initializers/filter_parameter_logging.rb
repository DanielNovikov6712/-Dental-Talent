# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # Candidate PII collected by the onboarding form (GDPR): keep it out of logs.
  :first_name, :last_name, :phone_number, :city, :country, :big_number,
  :desired_gross_salary, :average_daily_revenue, :motivation, :internal_notes, :professional_summary
]
