class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.role = "candidate"

    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome! Let's build your candidate profile."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
