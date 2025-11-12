Rails.application.routes.draw do
  get "home/index"
  devise_for :users

  authenticated :user do
    root to: 'home#index', as: :authenticated
  end

  unauthenticated do
    root to: redirect('/users/sign_in')
  end


  # root 'devise/sessions#new'

  # root 'home#index'

  get 'dashboard', to: 'home#dashboard'
  
  # get "up" => "rails/health#show", as: :rails_health_check

end
