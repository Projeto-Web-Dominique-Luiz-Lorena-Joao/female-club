class AddActiveToSuppliers < ActiveRecord::Migration[8.0]
  def change
    add_column :suppliers, :status, :string, default: "ativo"
  end
end
