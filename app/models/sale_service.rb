class SaleService < ApplicationRecord
  belongs_to :sale
  belongs_to :service, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }, if: :service_id_present?
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :service_id_present?
  validates :service_id, presence: true, if: :should_validate_service?

  def total_price
    quantity * unit_price
  end

  private

  def service_id_present?
    service_id.present?
  end

  def should_validate_service?
    # Só valida service_id se quantity ou unit_price foram preenchidos
    quantity.present? || unit_price.present?
  end
end
