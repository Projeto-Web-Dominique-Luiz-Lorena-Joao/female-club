class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # =============================================================================
    # ÍNDICES DE PERFORMANCE
    # Otimização para queries frequentes do sistema
    # =============================================================================

    # --- EMPLOYEES ---
    # Busca por status (listagem, contagens)
    add_index :employees, :status unless index_exists?(:employees, :status)
    # Busca por cargo
    add_index :employees, :position unless index_exists?(:employees, :position)
    # Ordenação por data de admissão
    add_index :employees, :admission_date unless index_exists?(:employees, :admission_date)
    # Busca textual por nome (para autocomplete)
    add_index :employees, :full_name, using: :gin, opclass: :gin_trgm_ops, name: 'idx_employees_full_name_trgm' unless index_exists?(:employees, :full_name, name: 'idx_employees_full_name_trgm')

    # --- CUSTOMERS ---
    # Busca por nome (autocomplete, listagem)
    add_index :customers, :full_name, using: :gin, opclass: :gin_trgm_ops, name: 'idx_customers_full_name_trgm' unless index_exists?(:customers, :full_name, name: 'idx_customers_full_name_trgm')
    # Busca por data de nascimento (aniversariantes)
    add_index :customers, :birth_date unless index_exists?(:customers, :birth_date)

    # --- PRODUCTS ---
    # Status de estoque (alertas, listagem filtrada)
    add_index :products, :stock_status unless index_exists?(:products, :stock_status)
    # Produtos ativos
    add_index :products, :active unless index_exists?(:products, :active)
    # Categoria
    add_index :products, :category unless index_exists?(:products, :category)
    # Busca por nome
    add_index :products, :name, using: :gin, opclass: :gin_trgm_ops, name: 'idx_products_name_trgm' unless index_exists?(:products, :name, name: 'idx_products_name_trgm')
    # Índice composto para listagem filtrada
    add_index :products, [:active, :category, :stock_status], name: 'idx_products_listing' unless index_exists?(:products, [:active, :category, :stock_status], name: 'idx_products_listing')

    # --- SERVICES ---
    add_index :services, :active unless index_exists?(:services, :active)
    add_index :services, :name, using: :gin, opclass: :gin_trgm_ops, name: 'idx_services_name_trgm' unless index_exists?(:services, :name, name: 'idx_services_name_trgm')

    # --- SERVICE_APPOINTMENTS ---
    # Índice para calendário (busca por mês/ano)
    add_index :service_appointments, :appointment_date unless index_exists?(:service_appointments, :appointment_date)
    # Índice composto para listagem
    add_index :service_appointments, [:appointment_date, :status], name: 'idx_appointments_date_status' unless index_exists?(:service_appointments, [:appointment_date, :status], name: 'idx_appointments_date_status')

    # --- SUPPLIERS ---
    add_index :suppliers, :status unless index_exists?(:suppliers, :status)
    add_index :suppliers, :product_category unless index_exists?(:suppliers, :product_category)

    # --- GUARANTORS ---
    add_index :guarantors, :status unless index_exists?(:guarantors, :status)

    # --- PRODUCT_INPUTS ---
    add_index :product_inputs, :created_at unless index_exists?(:product_inputs, :created_at)
    add_index :product_inputs, :product_id unless index_exists?(:product_inputs, :product_id)

    # --- PRODUCT_OUTPUTS ---
    add_index :product_outputs, :created_at unless index_exists?(:product_outputs, :created_at)
    add_index :product_outputs, :product_id unless index_exists?(:product_outputs, :product_id)
  end
end
