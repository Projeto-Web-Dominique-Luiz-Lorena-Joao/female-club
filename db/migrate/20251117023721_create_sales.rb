class CreateSales < ActiveRecord::Migration[8.0]
  def change
    create_table :sales do |t|
      t.references :customer, foreign_key: true, null: true
      t.references :employee, foreign_key: true, null: false
      t.date :sale_date, null: false
      t.date :due_date
      t.decimal :discount_percentage, precision: 5, scale: 2, default: 0.0
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.string :payment_method, null: false
      t.text :notes
      t.string :status, null: false
      t.date :paid_date

      t.timestamps
    end

    add_index :sales, :sale_date
    add_index :sales, :status
    add_index :sales, :due_date
    add_index :sales, :paid_date
    add_index :sales, :payment_method
    add_index :sales, [:customer_id, :sale_date]
    add_index :sales, [:employee_id, :sale_date]
    add_index :sales, [:status, :due_date]
  end
end
