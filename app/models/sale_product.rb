class SaleProduct < ApplicationRecord
  belongs_to :sale
  belongs_to :product, optional: true
  has_many :stock_movements, dependent: :destroy

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }, if: :product_id_present?
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :product_id_present?
  validates :product_id, presence: true, if: :should_validate_product?
  validate :sufficient_stock_available, if: :product_id_present?

  def total_price
    quantity * unit_price
  end

  private

  def product_id_present?
    product_id.present?
  end

  def should_validate_product?
    # Só valida product_id se quantity ou unit_price foram preenchidos
    quantity.present? || unit_price.present?
  end

  def sufficient_stock_available
    return if product.blank? || quantity.blank?

    available_quantity = product.quantity || 0

    # Se está editando uma venda existente, precisa considerar a quantidade anterior
    # Exemplo:
    #   - Estoque original: 100 unidades
    #   - Venda criada com: 80 unidades → ProductOutput criada, estoque fica 20
    #   - Editar venda para: 50 unidades → quantidade_anterior era 80
    #   - Estoque ajustado: 20 (atual) + 80 (anterior) = 100 disponível para esta venda
    #   - 100 >= 50 → Validação passa ✓
    if persisted? && quantity_was.present?
      adjusted_available = available_quantity + quantity_was
      return if adjusted_available >= quantity

      errors.add(:quantity, "Estoque insuficiente! Disponível para esta venda: #{adjusted_available} unidades. Solicitado: #{quantity} unidades.")
    else
      # Nova venda - validação normal
      if available_quantity < quantity
        errors.add(:quantity, "Estoque insuficiente! Disponível: #{available_quantity} unidades. Solicitado: #{quantity} unidades.")
      end
    end
  end
end
