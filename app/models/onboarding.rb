# Namespace + convenience accessors for the onboarding module configuration
# (see config/onboarding.yml and config/initializers/onboarding.rb).
module Onboarding
  # File extensions accepted for CV uploads, paired with the content types in
  # config/onboarding.yml. Kept here because some browsers send a generic or
  # empty content type, so we accept on either signal.
  ALLOWED_EXTENSIONS = %w[.pdf .doc .docx].freeze

  module_function

  def config
    Rails.application.config.onboarding
  end

  def max_cv_size_mb
    config.max_cv_size_mb.to_i
  end

  def max_cv_size_bytes
    max_cv_size_mb.megabytes
  end

  def allowed_content_types
    Array(config.allowed_content_types)
  end

  def recruitment_team_email
    config.recruitment_team_email.presence
  end

  def webhook_url
    config.webhook_url.presence
  end

  def webhook_enabled?
    webhook_url.present?
  end
end
