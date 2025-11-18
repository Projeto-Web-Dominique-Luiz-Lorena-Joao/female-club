class FixProductActiveColumn < ActiveRecord::Migration[8.0]
  def up
    # Update existing data first
    execute <<-SQL
      UPDATE products SET active = CASE
        WHEN active IN ('Disponível', 'disponivel') THEN 'true'
        WHEN active IN ('Indisponível', 'indisponivel') THEN 'false'
        ELSE 'true'
      END;
    SQL

    # Change column type using CAST
    change_column :products, :active, :boolean, using: 'active::boolean', default: true
  end

  def down
    change_column :products, :active, :string
  end
end
