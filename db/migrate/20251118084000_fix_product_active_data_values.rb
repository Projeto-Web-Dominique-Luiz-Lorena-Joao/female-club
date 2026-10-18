class FixProductActiveDataValues < ActiveRecord::Migration[8.0]
  def up
    # Convert string values to proper boolean values
    execute <<-SQL
      UPDATE products SET active = CASE
        WHEN active::text IN ('true', 'disponivel', 't') THEN true
        WHEN active::text IN ('false', 'indisponivel', 'f') THEN false
        ELSE true
      END;
    SQL
  end

  def down
    # No rollback needed
  end
end
