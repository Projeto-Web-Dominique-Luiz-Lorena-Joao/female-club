class AddIndexesForYearlyReports < ActiveRecord::Migration[8.0]
  def change
    # Índices para Sales - otimizar buscas por data e status
    add_index :sales, [:sale_date, :status], name: 'index_sales_on_sale_date_and_status' unless index_exists?(:sales, [:sale_date, :status], name: 'index_sales_on_sale_date_and_status')
    add_index :sales, :sale_date, name: 'index_sales_on_sale_date' unless index_exists?(:sales, :sale_date)

    # Índices para Expenses - otimizar buscas por data e status
    add_index :expenses, [:expense_date, :status], name: 'index_expenses_on_expense_date_and_status' unless index_exists?(:expenses, [:expense_date, :status], name: 'index_expenses_on_expense_date_and_status')
    add_index :expenses, :expense_date, name: 'index_expenses_on_expense_date' unless index_exists?(:expenses, :expense_date)

    # Índices compostos para SaleProducts - otimizar queries de agregação
    add_index :sale_products, [:sale_id, :product_id], name: 'index_sale_products_on_sale_and_product' unless index_exists?(:sale_products, [:sale_id, :product_id], name: 'index_sale_products_on_sale_and_product')

    # Índices compostos para SaleServices - otimizar queries de agregação
    add_index :sale_services, [:sale_id, :service_id], name: 'index_sale_services_on_sale_and_service' unless index_exists?(:sale_services, [:sale_id, :service_id], name: 'index_sale_services_on_sale_and_service')

    # Índice para customer_id em Sales para otimizar top customers
    add_index :sales, :customer_id, name: 'index_sales_on_customer_id' unless index_exists?(:sales, :customer_id)
  end
end
