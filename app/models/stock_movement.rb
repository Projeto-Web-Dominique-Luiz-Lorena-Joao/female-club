class StockMovement < ApplicationRecord
  belongs_to :product
  belongs_to :employee
  belongs_to :sale, optional: true
  belongs_to :sale_product, optional: true

  enum :movement_type, {
    aquisicao: "aquisicao",
    venda: "venda",
    perda_extravio: "perda_extravio",
    devolucao: "devolucao",
    ajuste_estoque: "ajuste_estoque",
    transferencia: "transferencia"
  }

  validates :product_id, presence: true
  validates :employee_id, presence: true
  validates :movement_type, presence: true, inclusion: { in: movement_types.keys.map(&:to_s) }
  validates :quantity, presence: true, numericality: { only_integer: true }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_movement_type, ->(type) { where(movement_type: type) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :sales, -> { where(movement_type: 'venda') }
  scope :acquisitions, -> { where(movement_type: 'aquisicao') }
  scope :losses, -> { where(movement_type: 'perda_extravio') }

  def self.movement_type_labels
    {
      aquisicao: "Aquisição",
      venda: "Venda",
      perda_extravio: "Perda/Extravio",
      devolucao: "Devolução",
      ajuste_estoque: "Ajuste de Estoque",
      transferencia: "Transferência"
    }
  end

  def movement_label
    self.class.movement_type_labels[movement_type.to_sym] || movement_type
  end
end
