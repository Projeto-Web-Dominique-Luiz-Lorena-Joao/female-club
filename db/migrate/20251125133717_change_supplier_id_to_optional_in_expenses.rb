class ChangeSupplierIdToOptionalInExpenses < ActiveRecord::Migration[8.0]
  def change
    change_column_null :expenses, :supplier_id, true
  end
end
