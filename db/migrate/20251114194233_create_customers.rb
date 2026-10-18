class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :full_name
      t.string :cpf
      t.date :birth_date
      t.string :phone_number
      t.string :email
      t.text :full_address
      t.text :notes

      t.timestamps
    end

    add_index :customers, :full_name
    add_index :customers, :cpf, unique: true, where: "cpf IS NOT NULL"
    add_index :customers, :email, where: "email IS NOT NULL"
    add_index :customers, :phone_number
  end
end
