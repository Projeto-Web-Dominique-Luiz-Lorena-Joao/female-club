class SaleService < ApplicationRecord
  belongs_to :sale
  belongs_to :service

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sale_id, presence: true
  validates :service_id, presence: true

  def total_price
    quantity * unit_price
  end
end
