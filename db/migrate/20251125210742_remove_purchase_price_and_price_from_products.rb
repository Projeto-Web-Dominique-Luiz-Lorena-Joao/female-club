class RemovePurchasePriceAndPriceFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :purchase_price, :decimal
    remove_column :products, :price, :decimal
  end
end
