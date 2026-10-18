class FixNegativeStockValues < ActiveRecord::Migration[8.0]
  def up
    # Corrigir quantity_in negativo para 0
    execute <<-SQL
      UPDATE products
      SET quantity_in = 0
      WHERE quantity_in < 0;
    SQL

    # Atualizar stock_status dos produtos após correção
    Product.find_each do |product|
      product.update_stock_status!
    rescue => e
      Rails.logger.error "Erro ao atualizar stock_status do produto #{product.id}: #{e.message}"
    end
  end

  def down
    # Não há como reverter valores que foram corrigidos
    # Esta é uma operação de limpeza de dados
  end
end
