class CreateProductOutputs < ActiveRecord::Migration[8.0]
  def change
    create_table :product_outputs do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 0
      t.string :output_type, null: false
      t.datetime :date_output, null: false
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :product_outputs, :output_type
    add_index :product_outputs, :date_output
    add_index :product_outputs, [:product_id, :date_output]
    add_index :product_outputs, [:output_type, :date_output]
  end
end
