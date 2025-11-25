class AddActiveToSuppliers < ActiveRecord::Migration[8.0]
  def change
    add_column :suppliers, :active, :boolean, default: true, null: false
  end
end
