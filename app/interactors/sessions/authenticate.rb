module Sessions
  class Authenticate
    include Interactor

    def call
      user = User.authenticate_by(email_address: context.email_address, password: context.password)
      context.fail! unless user

      context.user = user
    end
  end
end
