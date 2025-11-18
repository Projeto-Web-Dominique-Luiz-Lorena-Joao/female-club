class Product < ApplicationRecord
  belongs_to :supplier, optional: true

  has_one_attached :cover_image

  has_many_attached :gallery_images

  validate :gallery_images_limit
  validates :name, presence: true
  validates :code, uniqueness: true, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :sale_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :min_stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :low_stock, -> { where('quantity <= min_stock') }
  scope :search, ->(term) {
    where('name ILIKE ? OR code ILIKE ? OR brand ILIKE ?', "%#{term}%", "%#{term}%", "%#{term}%")
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

  validates :name, presence: true
  validates :price, :purchase_price, :sale_price,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true


  def low_stock?
    quantity <= min_stock
  end

  def profit_margin
    return 0 if purchase_price.nil? || sale_price.nil? || purchase_price.zero?
    ((sale_price - purchase_price) / purchase_price * 100).round(2)
  end

  def stock_value
    (quantity || 0) * (purchase_price || 0)
  end

  private

  def normalize_strings
    self.name = name&.strip
    self.code = code&.strip&.upcase
    self.brand = brand&.strip
    self.category = category&.strip
  end

  def gallery_images_limit
    if gallery_images.attachments.size > 7
      errors.add(:gallery_images, "você só pode enviar até 7 fotos")
    end
  end
end
