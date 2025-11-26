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
  validate :quantity_cannot_exceed_available_stock

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

  # Callback para atualizar quantidade do produto
  before_create :update_product_quantity_on_create
  before_update :update_product_quantity_on_update
  after_destroy :update_product_quantity_on_destroy

  private

  def update_product_quantity_on_create
    product.update_stock_status
  end

  def update_product_quantity_on_update
    return unless quantity_changed? || product_id_changed?

    if product_id_changed?
      # Se mudou o produto, atualiza status do produto antigo
      old_product = Product.find(product_id_was)
      old_product.update_stock_status

      # E atualiza status do novo produto
      product.update_stock_status
    elsif quantity_changed?
      # Se apenas a quantidade mudou, atualiza status
      product.update_stock_status
    end
  end

  def update_product_quantity_on_destroy
    product.update_stock_status
  end

  def quantity_cannot_exceed_available_stock
    return unless product && quantity

    # Calcula o estoque disponível
    current_stock = product.quantity

    # Se for uma edição, adiciona a quantidade anterior ao estoque disponível
    if persisted?
      current_stock += quantity_was
    end

    # Verifica se a quantidade da saída excede o estoque disponível
    if quantity > current_stock
      errors.add(:quantity, "não pode exceder o estoque disponível (#{current_stock} unidades)")
    end
  end
end
