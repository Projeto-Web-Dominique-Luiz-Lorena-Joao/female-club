Rails.application.routes.draw do
  resources :expenses
  resources :service_appointments do
    collection do
      get :search_services
      get :search_employees
      get :search_customers
    end
  end

  resources :guarantors do
    collection do
      get :search_customers
    end
  end

  resources :employees # ÚNICA DECLARAÇÃO DE EMPLOYEES

  resources :suppliers do
    member do
      patch :reactivate
    end
  end

  resources :customers
  resources :products
  resources :services
  resources :product_inputs do
    collection do
      get :search_products
      get :list_products
      get :search_suppliers
      get :list_suppliers
    end
  end
  resources :product_outputs do
    collection do
      get :search_products
      get :list_products
    end
  end
  get "inventory_status", to: "inventory_status#index"
  resources :sales do
    collection do
      get :search_employees
      get :search_customers
      get :search_products
      get :search_services
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
  get "employee", to: "home#employees"
  get "customers", to: "home#customers"
  get "suppliers", to: "home#suppliers"
  get "sales", to: "home#sales"
  get "products", to: "home#products"
  get "services", to: "home#services"
  get "expenses", to: "home#expenses"

  # get "up" => "rails/health#show", as: :rails_health_check
end