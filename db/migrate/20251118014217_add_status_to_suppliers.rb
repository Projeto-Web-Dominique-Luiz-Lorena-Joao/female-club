class AddStatusToSuppliers < ActiveRecord::Migration[8.0]
  def change
    add_column :suppliers, :status, :string, default: 'ativo'
    add_index :suppliers, :status
  end
end
