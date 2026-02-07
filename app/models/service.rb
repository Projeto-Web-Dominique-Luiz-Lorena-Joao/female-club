class Service < ApplicationRecord
  enum :active, {
    ativo: "ativo",
    inativo: "inativo",
    arquivado: "arquivado"
  }

  validates :name, presence: true, length: { maximum: 255 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :active, presence: true, inclusion: { in: %w[ativo inativo arquivado] }

  has_many :sale_services, dependent: :restrict_with_error
  has_many :service_appointments, dependent: :restrict_with_error

  # Scopes (gerados automaticamente pelo enum)
  # scope :active, -> { where(status: 'ativo') }
  # scope :inactive, -> { where(status: 'inativo') }
  # scope :archived, -> { where(status: 'arquivado') }

  scope :ordered_by_name, -> { order(:name) }
  scope :available, -> { where(active: "ativo") }

  before_validation :set_default_status, on: :create

  def formatted_price
    "R$ #{'%.2f' % price.to_f}"
  end

  def status_badge_class
    case active
    when "ativo"
      "bg-green-100 text-green-800"
    when "inativo"
      "bg-yellow-100 text-yellow-800"
    when "arquivado"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def status_label
    I18n.t("activerecord.attributes.service.active.#{active}")
  end

  private

  def set_default_status
    self.active ||= "ativo"
  end
end
