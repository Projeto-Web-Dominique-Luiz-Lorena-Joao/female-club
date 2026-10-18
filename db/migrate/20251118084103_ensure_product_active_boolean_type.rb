class EnsureProductActiveBooleanType < ActiveRecord::Migration[8.0]
  def up
    # First convert string values to actual booleans using CASE
    execute <<-SQL
      UPDATE products SET active = CASE
        WHEN active::text IN ('true', 'disponivel', 't') THEN true
        ELSE false
      END
      WHERE active IS NOT NULL;
    SQL

    # Ensure the column type is boolean and set default
    change_column :products, :active, :boolean, default: true
  end

  def down
    change_column :products, :active, :string
  end
end
