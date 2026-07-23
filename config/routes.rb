Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication (Rails 8 built-in) + candidate self-registration.
  resource  :session, only: %i[new create destroy]
  resources :passwords, param: :token
  resource  :registration, only: %i[new create]

  # Candidate onboarding flow.
  namespace :onboarding do
    # Step 1 — CV upload
    resource :cv_upload, only: %i[show create], path: "cv"
    post "cv/continue", to: "cv_uploads#continue_manually", as: :continue_manually

    # CV processing state (polled) + private download
    resources :documents, only: %i[show] do
      member do
        get :status
        get :download
      end
    end

    # Step 2 — Review & complete profile (+ completed summary)
    resource :profile, only: %i[show edit update]
  end

  # Recruiter / admin: review completed candidate profiles.
  namespace :admin do
    resources :candidate_profiles, only: %i[index show] do
      get :cv, on: :member
    end
  end

  # Role-aware landing page.
  root "home#show"
end
