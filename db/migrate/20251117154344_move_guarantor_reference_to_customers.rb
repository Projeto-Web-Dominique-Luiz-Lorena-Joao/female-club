class MoveGuarantorReferenceToCustomers < ActiveRecord::Migration[8.0]
  def change
    remove_reference :guarantors, :customer, foreign_key: true

    add_reference :customers, :guarantor, foreign_key: true, type: :bigint
  end
end
