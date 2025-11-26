class ChangeQuantityInToInteger < ActiveRecord::Migration[8.0]
  def change
    change_column :products, :quantity_in, :integer, default: 0
  end
end
