class CreateGuarantors < ActiveRecord::Migration[8.0]
  def change
    create_table :guarantors do |t|
      t.references :customer, null: false, foreign_key: true, type: :bigint
      t.string :full_name, null: false
      t.string :cpf
      t.string :phone
      t.text :address
      t.string :relationship

      t.timestamps
    end

    add_index :guarantors, :cpf
    add_index :guarantors, :phone
    add_index :guarantors, :relationship
  end
end
