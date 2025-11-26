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

  after_create_commit :update_product_stock
  after_update_commit :handle_product_update
  after_destroy_commit :rollback_product_stock

  def total_cost
    (quantity || 0) * (unit_cost || 0)
  end

  private

  def update_product_stock
    product.with_lock do
      product.quantity_in = (product.quantity_in || 0) + quantity
      product.last_replenishment_date = Time.current
      product.save!
    end
  end

  def handle_product_update
    return unless saved_change_to_quantity? || saved_change_to_product_id?

    if saved_change_to_product_id?
      old_product = Product.find(product_id_before_last_save)
      old_quantity = quantity_before_last_save || quantity

      old_product.with_lock do
        new_qty_in = (old_product.quantity_in || 0) - old_quantity
        old_product.quantity_in = [new_qty_in, 0].max
        old_product.save!
      end

      product.with_lock do
        product.quantity_in = (product.quantity_in || 0) + quantity
        product.last_replenishment_date = Time.current
        product.save!
      end

    elsif saved_change_to_quantity?
      old_quantity = quantity_before_last_save
      difference = quantity - old_quantity

      product.with_lock do
        product.quantity_in = (product.quantity_in || 0) + difference
        product.last_replenishment_date = Time.current if difference > 0
        product.save!
      end
    end
  end

  def rollback_product_stock
    product.with_lock do
      new_quantity_in = (product.quantity_in || 0) - quantity

      # Garantir que o estoque não fique negativo
      product.quantity_in = [new_quantity_in, 0].max
      product.save!
    end
  end
end