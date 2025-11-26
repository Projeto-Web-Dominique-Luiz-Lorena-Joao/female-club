class ProductOutput < ApplicationRecord
  belongs_to :product
  belongs_to :created_by, class_name: 'User', optional: true

  enum :output_type, {
    venda: "venda",
    extravio: "extravio",
    perda: "perda",
    dano: "dano",
    tragedia_climatica: "tragedia_climatica",
    devolucao: "devolucao",
    outro: "outro"
  }

  validates :product_id, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :output_type, presence: true, inclusion: { in: output_types.keys.map(&:to_s) }
  validates :date_output, presence: true

  scope :recent, -> { order(date_output: :desc) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_output_type, ->(type) { where(output_type: type) }
  scope :by_date_range, ->(start_date, end_date) { where(date_output: start_date.beginning_of_day..end_date.end_of_day) }

  after_create_commit :update_product_stock
  after_update_commit :handle_product_update
  after_destroy_commit :rollback_product_stock

  def self.output_type_labels
    {
      venda: "Venda",
      extravio: "Extravio",
      perda: "Perda",
      dano: "Dano",
      tragedia_climatica: "Tragédia Climática",
      devolucao: "Devolução",
      outro: "Outro"
    }
  end

  def output_label
    self.class.output_type_labels[output_type.to_sym] || output_type
  end

  private

  def update_product_stock
    product.with_lock do
      product.quantity = (product.quantity || 0) - quantity
      product.quantity = 0 if product.quantity < 0
      product.save!
    end
  end

  def handle_product_update
    return unless saved_change_to_quantity? || saved_change_to_product_id?

    if saved_change_to_product_id?
      old_product = Product.find(product_id_before_last_save)
      old_quantity = quantity_before_last_save || quantity

      old_product.with_lock do
        old_product.quantity = (old_product.quantity || 0) + old_quantity
        old_product.save!
      end

      product.with_lock do
        product.quantity = (product.quantity || 0) - quantity
        product.quantity = 0 if product.quantity < 0
        product.save!
      end

    elsif saved_change_to_quantity?
      old_quantity = quantity_before_last_save
      difference = quantity - old_quantity

      product.with_lock do
        product.quantity = (product.quantity || 0) - difference
        product.quantity = 0 if product.quantity < 0
        product.save!
      end
    end
  end

  def rollback_product_stock
    product.with_lock do
      product.quantity = (product.quantity || 0) + quantity
      product.save!
    end
  end
end