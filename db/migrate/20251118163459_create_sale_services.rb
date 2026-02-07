class CreateSaleServices < ActiveRecord::Migration[8.0]
  def change
    create_table :sale_services do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :sale_services, [ :sale_id, :service_id ], unique: true
  end
end
