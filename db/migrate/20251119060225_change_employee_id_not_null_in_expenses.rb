class ChangeEmployeeIdNotNullInExpenses < ActiveRecord::Migration[8.0]
  def up
    change_column :expenses, :employee_id, :bigint, null: false
  end

  def down
    change_column :expenses, :employee_id, :bigint, null: true
  end
end
