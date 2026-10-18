class ChangeDiscountPercentageToIntegerInSales < ActiveRecord::Migration[8.0]
  def up
    # Primeiro, converte os valores decimais existentes para inteiros
    execute <<-SQL
      UPDATE sales
      SET discount_percentage = ROUND(discount_percentage)
      WHERE discount_percentage IS NOT NULL
    SQL

    # Depois muda o tipo da coluna
    change_column :sales, :discount_percentage, :integer, default: 0
  end

  def down
    change_column :sales, :discount_percentage, :decimal, precision: 5, scale: 2, default: 0.0
  end
end
