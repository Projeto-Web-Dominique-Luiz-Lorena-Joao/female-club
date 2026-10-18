class FixProductQuantityType < ActiveRecord::Migration[8.0]
  def change
    # First, set any negative quantities to 0
    execute "UPDATE products SET quantity = 0 WHERE quantity < 0 OR quantity IS NULL"

    # Change column type from float to integer
    change_column :products, :quantity, :integer, default: 0, null: false
  end
end
