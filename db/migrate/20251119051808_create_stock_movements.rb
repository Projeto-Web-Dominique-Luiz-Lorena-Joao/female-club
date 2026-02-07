class CreateStockMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.references :sale, null: true, foreign_key: true
      t.references :sale_product, null: true, foreign_key: true
      t.string :movement_type, null: false
      t.integer :quantity, null: false, default: 0
      t.text :description

      t.timestamps
    end

    add_index :stock_movements, [ :product_id, :created_at ]
    add_index :stock_movements, :movement_type
  end
end
