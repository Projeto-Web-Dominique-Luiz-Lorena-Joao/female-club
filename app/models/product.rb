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
  validates :sale_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :min_stock, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :search, ->(term) {
    where("name ILIKE ? OR code ILIKE ? OR brand ILIKE ?", "%#{term}%", "%#{term}%", "%#{term}%")
  }

  before_save :normalize_strings

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
    total_inputs - total_outputs
  end

  def low_stock?
    return false unless min_stock
    quantity <= min_stock
  end

  def stock_value
    quantity * (sale_price || 0)
  end

  def update_stock_status
    if quantity.nil? || quantity <= 0
      self.stock_status = "fora_de_estoque"
    elsif min_stock && quantity < min_stock
      self.stock_status = "critico"
    elsif min_stock && quantity < (min_stock + 3)
      self.stock_status = "baixo"
    else
      self.stock_status = "em_estoque"
    end
    save
  end

  private

  def normalize_strings
    self.name = name&.strip
    self.code = code&.strip&.upcase
    self.brand = brand&.strip
    self.category = category&.strip
  end
end
