class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    result = Registrations::RegisterCandidate.call(attributes: registration_params)

    if result.success?
      start_new_session_for result.user
      redirect_to after_authentication_url, notice: "Welcome! Let's build your candidate profile."
    else
      @user = result.user
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
