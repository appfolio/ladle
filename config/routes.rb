Rails.application.routes.draw do
  post 'github_events/payload', constraints: { format: 'json' }

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  resource :user_settings, only: [:edit, :update]
  resources :pull_requests

  root to: "home#index"
end
