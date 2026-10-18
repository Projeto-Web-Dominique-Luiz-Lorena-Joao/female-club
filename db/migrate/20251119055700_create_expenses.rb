class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.date :expense_date, null: false
      t.string :expense_type, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :payment_method, null: false
      t.text :notes
      t.string :category, null: false

      t.timestamps
    end

    add_index :expenses, [ :employee_id, :created_at ]
    add_index :expenses, :expense_type
    add_index :expenses, :category
    add_index :expenses, :expense_date
  end
end
