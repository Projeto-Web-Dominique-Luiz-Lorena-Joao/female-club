class CreateSuppliers < ActiveRecord::Migration[8.0]
  def change
    create_table :suppliers do |t|
      t.string :legal_name, null: false
      t.string :trade_name
      t.string :phone_number
      t.string :email
      t.text :full_address
      t.string :product_category
      t.text :notes

      t.timestamps
    end

    add_index :suppliers, :legal_name
    add_index :suppliers, :trade_name
    add_index :suppliers, :product_category
  end
end
