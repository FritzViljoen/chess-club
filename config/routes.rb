Rails.application.routes.draw do
  resources :people
  resources :contests
  get "standings", to: "standings#show"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  root "standings#show"
end
