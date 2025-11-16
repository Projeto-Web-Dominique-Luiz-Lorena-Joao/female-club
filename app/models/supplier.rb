class Supplier < ApplicationRecord

  # has_many :stock_items, dependent: :nullify
  # has_many :stock_movements, dependent: :nullify
  # has_many :monthly_expenses, dependent: :nullify
  # has_many :expenses, dependent: :nullify

  enum :product_category, {
    cosmeticos: 'cosmeticos',
    maquiagem: 'maquiagem',
    perfumaria: 'perfumaria',
    cabelo: 'cabelo',
    unhas: 'unhas',
    pele: 'pele',
    acessorios: 'acessorios',
    equipamentos: 'equipamentos',
    diversos: 'diversos'
  }, suffix: true

  validates :legal_name, presence: true, length: { minimum: 3 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :active, -> { joins(:stock_items).distinct }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(product_category: category) if category.present? }

  def display_name
    trade_name.presence || legal_name
  end

  def formatted_phone
    return '-' if phone_number.blank?
    phone_number.gsub(/(\d{2})(\d{5})(\d{4})/, '(\1) \2-\3')
  end

  # def total_items_supplied
  #   stock_items.count
  # end

  # def items_in_stock
  #   stock_items.where('quantity > 0').count
  # end

  # def total_stock_value
  #   stock_items.sum('quantity * sale_price')
  # end

  # def last_supply_date
  #   stock_movements.where(movement_type: 'entrada').maximum(:movement_date)
  # end

  def category_badge_color
    case product_category
    when 'cosmeticos' then 'bg-pink-100 text-pink-800'
    when 'maquiagem' then 'bg-purple-100 text-purple-800'
    when 'perfumaria' then 'bg-blue-100 text-blue-800'
    when 'cabelo' then 'bg-green-100 text-green-800'
    when 'unhas' then 'bg-red-100 text-red-800'
    when 'pele' then 'bg-yellow-100 text-yellow-800'
    when 'acessorios' then 'bg-indigo-100 text-indigo-800'
    when 'equipamentos' then 'bg-gray-100 text-gray-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
end