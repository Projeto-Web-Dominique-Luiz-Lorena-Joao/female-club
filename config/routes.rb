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
      get :check_conflicts
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
  resources :services do
    member do
      patch :change_status
    end
  end

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

  # --- RELATÓRIOS ---
  get "daily_reports", to: "daily_reports#index", as: :daily_reports
  get "monthly_reports", to: "monthly_reports#index", as: :monthly_reports
  get "yearly_reports", to: "yearly_reports#index", as: :yearly_reports

  # --- CALENDÁRIO DE AGENDAMENTOS ---
  get "appointments_calendar", to: "appointments_calendar#index", as: :appointments_calendar

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

  # --- SOLICITAÇÕES DE ACESSO ---
  resources :access_requests, only: [ :new, :create ]

  namespace :admin do
    resources :access_requests, only: [ :index ] do
      member do
        patch :approve
        patch :reject
      end
    end

    resources :users, only: [ :index ] do
      member do
        patch :deactivate
        patch :reactivate
      end
    end
  end

  devise_for :users, controllers: {
    registrations: "users/registrations",
    passwords: "users/passwords"
  }

  # Rota para atualizar preferência de paginação
  patch "update_pagination_preference", to: "application#update_pagination_preference", as: :update_pagination_preference

  authenticated :user do
    root to: "home#dashboard", as: :authenticated_root
  end

  unauthenticated do
    root to: redirect("/users/sign_in")
  end

  get "dashboard", to: "home#dashboard"

  get "employee", to: "home#employees"
  get "customers", to: "home#customers"
  get "suppliers", to: "home#suppliers"
  get "sales", to: "home#sales"
  get "products", to: "home#products"
  get "services", to: "home#services"
  get "expenses", to: "home#expenses"
end
