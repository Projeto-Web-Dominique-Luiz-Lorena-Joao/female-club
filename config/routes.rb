Rails.application.routes.draw do

  resources :suppliers
  resources :employees
  resources :customers
  resources :sales

  devise_for :users

  authenticated :user do
    root to: "home#dashboard", as: :authenticated_root
  end

  unauthenticated do
    root to: redirect("/users/sign_in")
  end

  get "dashboard", to: "home#dashboard"

  # root 'devise/sessions#new'

  # root 'home#index'
  get 'employee', to: 'home#employees'
  get 'dashboard', to: 'home#dashboard'
  get 'customers', to: 'home#customers'
  get 'suppliers', to: 'home#suppliers'
  get 'sales', to: 'home#sales'

  # get "up" => "rails/health#show", as: :rails_health_check
end
