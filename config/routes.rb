# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    get "employees/search", to: "employees#search"
    get "suppliers/search", to: "suppliers#search"
  end

  resources :expenses do
    member do
      patch :cancel
      patch :reactivate
    end
  end

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

  resources :employees do
    member do
      patch :reactivate
    end
  end

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

  # --- ESTOQUE PRINCIPAL (botão do menu) ---
  get "inventory", to: "inventory#index", as: :inventory

  # --- ESTADO DO ESTOQUE (submenu) ---
  get "inventory_status", to: "inventory_status#index", as: :inventory_status

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
    # ALTERADO: Usar o novo DashboardController
    root to: "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    root to: redirect("/users/sign_in")
  end

  # ALTERADO: Rota do dashboard usando o novo controller
  get "dashboard", to: "dashboard#index"

  # Manter rotas antigas do HomeController se ainda precisar
  get "employee", to: "home#employees"
  get "customers_page", to: "home#customers"
  get "suppliers_page", to: "home#suppliers"
  get "sales_page", to: "home#sales"
  get "products_page", to: "home#products"
  get "services_page", to: "home#services"
  get "expenses_page", to: "home#expenses"
end