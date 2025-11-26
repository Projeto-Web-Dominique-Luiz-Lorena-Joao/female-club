class Product < ApplicationRecord
  belongs_to :supplier, optional: true

  has_one_attached :cover_image

  has_many :sale_products, dependent: :destroy
  has_many :sales, through: :sale_products
  has_many :stock_movements, dependent: :destroy
  has_many :product_outputs, dependent: :destroy
  has_many :product_inputs, dependent: :destroy

  validates :name, presence: true
  validates :code, uniqueness: true, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :sale_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :min_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :low_stock, -> { where('quantity <= min_stock') }
  scope :search, ->(term) {
    where('name ILIKE ? OR code ILIKE ? OR brand ILIKE ?', "%#{term}%", "%#{term}%", "%#{term}%")
  }

  before_save :normalize_strings
  after_save :update_stock_status_if_needed

  enum :category, {
    beleza_cosmeticos: "Beleza e Cosméticos",
    moda_acessorios: "Moda e Acessórios",
    bem_estar_autocuidado: "Bem-estar e Produtos Naturais",
    decoracao_casa: "Decoração e Casa",
    gastronomia_bebidas: "Gastronomia e Bebidas",
    livros_cultura: "Livros e Cultura",
    tecnologia_lifestyle: "Tecnologia e Lifestyle",
    fitness_esportes: "Fitness e Esportes",
    outros: "Outros"
  }

  def low_stock?
    return false if min_stock.blank?
    quantity.to_i <= min_stock
  end

  def profit_margin
    return 0 if purchase_price.nil? || sale_price.nil? || purchase_price.zero?
    ((sale_price - purchase_price) / purchase_price * 100).round(2)
  end

  def stock_value
    (quantity || 0) * (purchase_price || 0)
  end

  def update_stock_status!
    new_status = calculate_stock_status
    update_column(:stock_status, new_status) if stock_status != new_status
  end

  def calculate_stock_status
    current_quantity = quantity.to_i
    minimum_stock = min_stock.to_i

    return "fora_de_estoque" if current_quantity <= 0

    return "em_estoque" if minimum_stock <= 0

    low_stock_limit = minimum_stock * 2

    if current_quantity <= minimum_stock
      "critico"
    elsif current_quantity <= low_stock_limit
      "baixo"
    else
      "em_estoque"
    end
  end

  def stock_status_info
    return "Sem estoque mínimo definido" if min_stock.blank? || min_stock <= 0

    low_stock_limit = min_stock * 2
    
    {
      quantity: quantity.to_i,
      min_stock: min_stock,
      low_stock_limit: low_stock_limit,
      status: stock_status,
      message: stock_status_message
    }
  end

  def stock_status_message
    current_quantity = quantity.to_i
    minimum_stock = min_stock.to_i

    return "Produto fora de estoque" if current_quantity <= 0
    return "Estoque não configurado" if minimum_stock <= 0

    low_stock_limit = minimum_stock * 2

    case stock_status
    when "critico"
      "Crítico! #{current_quantity} unidades (mínimo: #{minimum_stock})"
    when "baixo"
      "Estoque baixo! #{current_quantity} unidades (repor quando chegar em #{minimum_stock})"
    when "em_estoque"
      "Em estoque: #{current_quantity} unidades"
    else
      "Fora de estoque"
    end
  end

  private

  def normalize_strings
    self.name = name&.strip
    self.code = code&.strip&.upcase
    self.brand = brand&.strip
    self.category = category&.strip
  end

  def update_stock_status_if_needed
    if saved_change_to_quantity? || saved_change_to_min_stock?
      update_stock_status!
    end
  end
end