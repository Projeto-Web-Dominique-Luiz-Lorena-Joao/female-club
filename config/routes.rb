Rails.application.routes.draw do

  resources :employees

  devise_for :users

  authenticated :user do
    root to: 'home#index', as: :authenticated
  end

  unauthenticated do
    root to: redirect('/users/sign_in')
  end


  # root 'devise/sessions#new'

  # root 'home#index'
  get 'employee', to: 'home#employees'
  get 'dashboard', to: 'home#dashboard'

  # get "up" => "rails/health#show", as: :rails_health_check

end
