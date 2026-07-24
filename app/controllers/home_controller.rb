class HomeController < ApplicationController
  def show
    if Current.user.staff?
      redirect_to admin_candidate_profiles_path
    else
      redirect_to onboarding_cv_upload_path
    end
  end
end
