class AdminMailer < ApplicationMailer
  # Sent to the recruitment team when a candidate completes onboarding.
  def candidate_onboarding_completed(profile)
    @profile = profile
    @name    = profile.full_name.presence || profile.email
    @function = Onboarding::Options.label(Onboarding::Options::JOB_FUNCTIONS, profile.desired_job_function)

    mail to: Onboarding.recruitment_team_email,
      subject: "New candidate profile completed: #{@name}"
  end
end
