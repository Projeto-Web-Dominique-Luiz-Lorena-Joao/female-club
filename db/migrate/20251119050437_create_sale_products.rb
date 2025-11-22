class CreateSaleProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :sale_products do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :sale_products, [:sale_id, :product_id], unique: true
  end
end
