Rails.application.routes.draw do

  resources :suppliers
  resources :employees
  resources :guarantors do
    collection do
      get :search_customers
    end
  end
  resources :customers
  resources :products
  resources :services
  resources :sales do
    collection do
      get :search_employees
      get :search_customers
    end
    member do
      patch :mark_as_paid
    end
  end

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
  get 'customers', to: 'home#customers'
  get 'suppliers', to: 'home#suppliers'
  get 'sales', to: 'home#sales'
  get 'products', to: 'home#products'
  get 'services', to: 'home#services'

  # get "up" => "rails/health#show", as: :rails_health_check
end
