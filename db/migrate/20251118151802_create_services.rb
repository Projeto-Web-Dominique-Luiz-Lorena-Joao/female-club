class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :active, default: 'active', null: false

      t.timestamps
    end

    add_index :services, :name
    add_index :services, :active
  end
end
