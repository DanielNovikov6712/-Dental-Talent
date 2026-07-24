module SessionHelpers
  def sign_in_as(user)
    session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |jar|
      jar.signed[:session_id] = session.id
      cookies[:session_id] = jar[:session_id]
    end

    session
  end
end
