module Onboarding
  class BaseController < ApplicationController
    before_action :redirect_staff_to_admin
    before_action :set_candidate_profile

    private

    # Staff members don't onboard; send them to the review area.
    def redirect_staff_to_admin
      redirect_to admin_candidate_profiles_path if Current.user.staff?
    end

    def set_candidate_profile
      @candidate_profile = Current.user.candidate_profile!
    end
  end
end
