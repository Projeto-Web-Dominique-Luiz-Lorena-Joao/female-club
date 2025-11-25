class AddStatusToGuarantors < ActiveRecord::Migration[8.0]
  def change
    add_column :guarantors, :status, :string, null: false, default: 'ativo'
    add_index :guarantors, :status
  end
end
