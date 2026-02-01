class Product < ApplicationRecord
  belongs_to :supplier, optional: true

  has_one_attached :cover_image

  # SEGURANÇA: Validação de upload de imagem
  validate :acceptable_cover_image

  has_many :sale_products, dependent: :destroy
  has_many :sales, through: :sale_products
  has_many :stock_movements, dependent: :destroy
  has_many :product_outputs, dependent: :destroy
  has_many :product_inputs, dependent: :destroy

  validates :name, presence: true
  validates :code, uniqueness: true, allow_nil: true
  validates :sale_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :min_stock, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :quantity_in, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :low_stock, -> { where(stock_status: ['critico', 'baixo']) }
  scope :search, ->(term) {
    where("name ILIKE ? OR code ILIKE ? OR brand ILIKE ?", "%#{term}%", "%#{term}%", "%#{term}%")
  }

  before_save :normalize_strings
  before_save :ensure_non_negative_stock
  after_save :update_stock_status_if_needed
  after_create_commit :update_stock_status!
  after_update_commit :update_stock_status!

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



  # Calcula a quantidade atual baseada nas entradas e saídas
  def quantity
    total_inputs = product_inputs.sum(:quantity)
    total_outputs = product_outputs.sum(:quantity)
    calculated_quantity = total_inputs - total_outputs
    # Garantir que nunca retorne valor negativo
    [calculated_quantity, 0].max
  end

  def low_stock?
    return false unless min_stock
    quantity <= min_stock
  end

  def stock_value
    quantity * (sale_price || 0)
  end

  def update_stock_status!
    new_status = calculate_stock_status
    update_column(:stock_status, new_status) if stock_status != new_status
  end

  def refresh_stock_status!
    new_status = calculate_stock_status
    update_column(:stock_status, new_status)
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

  def category_badge_class
    case category
    when "beleza_cosmeticos"
      'bg-pink-100 text-pink-800'
    when "moda_acessorios"
      'bg-purple-100 text-purple-800'
    when "bem_estar_autocuidado"
      'bg-green-100 text-green-800'
    when "decoracao_casa"
      'bg-yellow-100 text-yellow-800'
    when "gastronomia_bebidas"
      'bg-orange-100 text-orange-800'
    when "livros_cultura"
      'bg-indigo-100 text-indigo-800'
    when "tecnologia_lifestyle"
      'bg-cyan-100 text-cyan-800'
    when "fitness_esportes"
      'bg-blue-100 text-blue-800'
    when "outros"
      'bg-gray-100 text-gray-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  private

  def normalize_strings
    self.name = name&.strip
    self.code = code&.strip&.upcase
    self.brand = brand&.strip
    self.category = category&.strip
  end

  def ensure_non_negative_stock
    # Garantir que quantity_in nunca seja negativo
    self.quantity_in = 0 if quantity_in && quantity_in < 0
  end

  def update_stock_status_if_needed
    if saved_change_to_quantity_in? || saved_change_to_min_stock?
      update_stock_status!
    end
  end

  # SEGURANÇA: Validação de arquivo de imagem
  def acceptable_cover_image
    return unless cover_image.attached?

    # Validar tipo de arquivo (MIME type)
    acceptable_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    unless acceptable_types.include?(cover_image.content_type)
      errors.add(:cover_image, 'deve ser uma imagem (JPEG, PNG, GIF ou WebP)')
    end

    # Validar tamanho do arquivo (máximo 5MB)
    if cover_image.byte_size > 5.megabytes
      errors.add(:cover_image, 'é muito grande (máximo 5MB)')
    end
  end
end