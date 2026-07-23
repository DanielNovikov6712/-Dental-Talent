require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { users(:candidate) }

  it "renders the forgot-password page" do
    get new_password_path
    expect(response).to have_http_status(:success)
  end

  it "sends reset instructions for a known user" do
    expect { post passwords_path, params: { email_address: user.email_address } }
      .to have_enqueued_mail(PasswordsMailer, :reset)
    expect(response).to redirect_to(new_session_path)
  end

  it "redirects without sending mail for an unknown user" do
    expect { post passwords_path, params: { email_address: "missing@example.com" } }
      .not_to have_enqueued_mail(PasswordsMailer, :reset)
    expect(response).to redirect_to(new_session_path)
  end

  it "resets the password with a valid token" do
    get edit_password_path(user.password_reset_token)
    expect(response).to have_http_status(:success)

    put password_path(user.password_reset_token),
      params: { password: "newpassword", password_confirmation: "newpassword" }
    expect(response).to redirect_to(new_session_path)
  end

  it "rejects an invalid token" do
    get edit_password_path("bogus-token")
    expect(response).to redirect_to(new_password_path)
  end

  it "rejects non-matching passwords" do
    token = user.password_reset_token
    put password_path(token), params: { password: "newpassword", password_confirmation: "different" }
    expect(response).to redirect_to(edit_password_path(token))
  end
end
