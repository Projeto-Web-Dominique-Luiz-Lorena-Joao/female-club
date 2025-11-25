class ProductInput < ApplicationRecord
  belongs_to :product
  belongs_to :supplier, optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  validates :product_id, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :date_input, presence: true
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :recent, -> { order(date_input: :desc) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_supplier, ->(supplier_id) { where(supplier_id: supplier_id) }
  scope :by_date_range, ->(start_date, end_date) { where(date_input: start_date..end_date) }

  # Callback para atualizar quantidade do produto
  before_create :update_product_quantity_on_create
  before_update :update_product_quantity_on_update
  after_destroy :update_product_quantity_on_destroy

  def total_cost
    (quantity || 0) * (unit_cost || 0)
  end

  private

  def update_product_quantity_on_create
    product.increment!(:quantity, quantity)
    product.increment!(:quantity_in, quantity)
    product.update(last_replenishment_date: Time.current)
    product.update_stock_status
  end

  def update_product_quantity_on_update
    return unless quantity_changed? || product_id_changed?

    if product_id_changed?
      # Se mudou o produto, reverte a quantidade no produto antigo
      old_product = Product.find(product_id_was)
      old_product.decrement!(:quantity, quantity_was)
      old_product.decrement!(:quantity_in, quantity_was)
      old_product.update_stock_status

      # E aplica no novo produto
      product.increment!(:quantity, quantity)
      product.increment!(:quantity_in, quantity)
      product.update(last_replenishment_date: Time.current)
      product.update_stock_status
    elsif quantity_changed?
      # Se apenas a quantidade mudou, ajusta a diferença
      difference = quantity - quantity_was
      product.increment!(:quantity, difference)
      product.increment!(:quantity_in, difference)
      product.update_stock_status
    end
  end

  def update_product_quantity_on_destroy
    product.decrement!(:quantity, quantity)
    product.decrement!(:quantity_in, quantity)
    product.update_stock_status
  end
end
