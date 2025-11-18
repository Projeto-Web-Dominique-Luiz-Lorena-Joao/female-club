class ResetProductActiveValues < ActiveRecord::Migration[8.0]
  def up
    # Set all products to disponivel (true) by default
    execute "UPDATE products SET active = true WHERE active IS NULL OR active = 'f' OR active = false"
  end

  def down
    # Nothing to do on rollback
  end
end
