class RemoveQuantityFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :quantity, :integer
  end
end
