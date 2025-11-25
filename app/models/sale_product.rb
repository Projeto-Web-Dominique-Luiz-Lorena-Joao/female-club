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

    if available_quantity < quantity
      errors.add(:quantity, "Estoque insuficiente! Disponível: #{available_quantity} unidades. Solicitado: #{quantity} unidades.")
    end
  end
end
