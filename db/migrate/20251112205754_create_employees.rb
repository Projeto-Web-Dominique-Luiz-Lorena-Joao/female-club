class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.string :full_name, null: false
      t.string :cpf, null: false
      t.string :position
      t.string :phone
      t.string :email
      t.text :address
      t.date :admission_date
      t.decimal :salary, precision: 10, scale: 2
      t.string :work_days
      t.text :notes
      t.string :status, default: 'ativo'

      t.timestamps
    end

    add_index :employees, :full_name
    add_index :employees, :cpf, unique: true
    add_index :employees, :position
    add_index :employees, :status
  end
end
