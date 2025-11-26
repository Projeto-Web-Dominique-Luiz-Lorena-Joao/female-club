class ProductOutput < ApplicationRecord
  belongs_to :product
  belongs_to :created_by, class_name: 'User', optional: true

  attr_accessor :skip_stock_validation

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
  validate :ensure_sufficient_stock, on: :create
  validate :ensure_sufficient_stock_on_update, on: :update

  after_destroy :update_product_stock_status

  scope :recent, -> { order(date_output: :desc) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_output_type, ->(type) { where(output_type: type) }
  scope :by_date_range, ->(start_date, end_date) { where(date_output: start_date.beginning_of_day..end_date.end_of_day) }


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

  def ensure_sufficient_stock
    return if skip_stock_validation
    return unless product && quantity

    available_stock = product.quantity
    if available_stock < quantity
      errors.add(:base, "Quantidade insuficiente em estoque. Disponível: #{available_stock} unidade(s)")
    end
  end

  def ensure_sufficient_stock_on_update
    return if skip_stock_validation
    return unless product && quantity
    return unless saved_change_to_quantity? || saved_change_to_product_id?

    if saved_change_to_product_id?
      # Verificar se o novo produto tem estoque suficiente
      available_stock = product.quantity
      if available_stock < quantity
        errors.add(:base, "Quantidade insuficiente no produto selecionado. Disponível: #{available_stock} unidade(s)")
      end
    elsif saved_change_to_quantity?
      # Verificar se há estoque suficiente para a diferença
      old_quantity = quantity_before_last_save || 0
      difference = quantity - old_quantity

      if difference > 0
        available_stock = product.quantity
        if available_stock < difference
          errors.add(:base, "Quantidade insuficiente em estoque. Disponível para adicionar: #{available_stock} unidade(s)")
        end
      end
    end
  end

  def update_product_stock_status
    product&.update_stock_status!
  end

end