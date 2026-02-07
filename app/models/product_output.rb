class ProductOutput < ApplicationRecord
  belongs_to :product
  belongs_to :created_by, class_name: "User", optional: true

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

  def output_badge_class
    case output_type.to_sym
    when :venda
      "bg-green-100 text-green-800"
    when :extravio
      "bg-orange-100 text-orange-800"
    when :perda
      "bg-red-100 text-red-800"
    when :dano
      "bg-yellow-100 text-yellow-800"
    when :tragedia_climatica
      "bg-purple-100 text-purple-800"
    when :devolucao
      "bg-blue-100 text-blue-800"
    when :outro
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  private

  def ensure_sufficient_stock
    return unless product && quantity

    available_stock = product.quantity
    if available_stock < quantity
      errors.add(:base, "Quantidade insuficiente em estoque. Disponível: #{available_stock} unidade(s)")
    end
  end

  def ensure_sufficient_stock_on_update
    return unless product && quantity
    return unless will_save_change_to_quantity? || will_save_change_to_product_id?

    if will_save_change_to_product_id?
      # Verificar se o novo produto tem estoque suficiente
      available_stock = product.quantity
      if available_stock < quantity
        errors.add(:base, "Quantidade insuficiente no produto selecionado. Disponível: #{available_stock} unidade(s)")
      end
    elsif will_save_change_to_quantity?
      # Verificar se há estoque suficiente para a diferença
      old_quantity = quantity_in_database || 0
      difference = quantity - old_quantity

      if difference > 0
        available_stock = product.quantity
        if available_stock < difference
          errors.add(:base, "Quantidade insuficiente em estoque. Disponível para adicionar: #{available_stock} unidade(s)")
        end
      end
    end
  end
end
