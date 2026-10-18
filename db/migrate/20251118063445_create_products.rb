class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :supplier, foreign_key: true, null: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2
      t.string :active
      t.string :brand
      t.string :color
      t.float :quantity
      t.decimal :purchase_price, precision: 10, scale: 2
      t.decimal :sale_price, precision: 10, scale: 2
      t.string :category
      t.integer :min_stock
      t.text :location
      t.text :notes
      t.string :unit
      t.string :code

      t.timestamps
    end
  end
end
