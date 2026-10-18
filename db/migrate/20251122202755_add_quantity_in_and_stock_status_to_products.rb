class AddQuantityInAndStockStatusToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :quantity_in, :float, default: 0
    add_column :products, :stock_status, :string, default: "normal"
    add_column :products, :last_replenishment_date, :datetime

    add_index :products, :stock_status
  end
end
