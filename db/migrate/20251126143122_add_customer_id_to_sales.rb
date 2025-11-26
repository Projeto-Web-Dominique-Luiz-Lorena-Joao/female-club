class AddCustomerIdToSales < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:sales, :customer_id)
      add_reference :sales, :customer, foreign_key: true
    end
  end
end