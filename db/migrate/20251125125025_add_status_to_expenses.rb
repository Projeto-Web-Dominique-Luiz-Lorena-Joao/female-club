class AddStatusToExpenses < ActiveRecord::Migration[8.0]
  def change
    add_column :expenses, :status, :string, default: "ativa", null: false
  end
end
