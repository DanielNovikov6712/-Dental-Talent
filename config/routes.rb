Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource  :session, only: %i[new create destroy]
  resources :passwords, param: :token
  resource  :registration, only: %i[new create]

  namespace :onboarding do
    resource :cv_upload, only: %i[show create], path: "cv"
    post "cv/continue", to: "cv_uploads#continue_manually", as: :continue_manually

    resources :documents, only: %i[show] do
      member do
        get :status
        get :download
      end
    end

    resource :profile, only: %i[show edit update]
  end

  namespace :admin do
    resources :candidate_profiles, only: %i[index show] do
      get :cv, on: :member
    end
  end

  root "home#show"
end
