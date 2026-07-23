module Admin
  class BaseController < ApplicationController
    before_action :require_staff

    private

    def require_staff
      redirect_to root_path, alert: "You are not authorized to view that page." unless Current.user.staff?
    end
  end
end
