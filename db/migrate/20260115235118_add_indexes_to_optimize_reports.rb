class AddIndexesToOptimizeReports < ActiveRecord::Migration[8.0]
  def change
    # Índices para a tabela sales (otimizar queries de relatórios)
    add_index :sales, [:sale_date, :status] unless index_exists?(:sales, [:sale_date, :status])
    add_index :sales, [:due_date, :status] unless index_exists?(:sales, [:due_date, :status])

    # Índices para a tabela expenses
    add_index :expenses, [:expense_date, :status] unless index_exists?(:expenses, [:expense_date, :status])
    add_index :expenses, [:category, :status] unless index_exists?(:expenses, [:category, :status])

    # Índices compostos para queries complexas dos relatórios
    add_index :sales, [:sale_date, :customer_id, :status] unless index_exists?(:sales, [:sale_date, :customer_id, :status])
  end
end
