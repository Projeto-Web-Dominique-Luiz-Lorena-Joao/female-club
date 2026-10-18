class CreateProductInputs < ActiveRecord::Migration[8.0]
  def change
    create_table :product_inputs do |t|
      t.references :product, null: false, foreign_key: true
      t.references :supplier, foreign_key: true
      t.integer :quantity, null: false, default: 0
      t.decimal :unit_cost, precision: 10, scale: 2
      t.datetime :date_input, null: false
      t.string :invoice_number
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :product_inputs, :date_input
    add_index :product_inputs, [ :product_id, :date_input ]
    add_index :product_inputs, [ :supplier_id, :date_input ]
  end
end
