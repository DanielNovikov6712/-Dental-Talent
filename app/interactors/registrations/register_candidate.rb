module Registrations
  class RegisterCandidate
    include Interactor

    def call
      user = User.new(context.attributes)
      user.role = "candidate"
      context.user = user

      context.fail! unless user.save
    end
  end
end
