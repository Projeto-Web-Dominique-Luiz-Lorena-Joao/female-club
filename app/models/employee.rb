class Employee < ApplicationRecord
  # has_many :sales, dependent: :nullify
  # has_many :stock_movements, dependent: :nullify
  # has_many :expenses, dependent: :nullify
  # has_many :incomes, dependent: :nullify
  # has_many :service_appointments, dependent: :nullify


  enum :position, {
    gerente: 'gerente',
    vendedor: 'vendedor',
    caixa: 'caixa',
    estoquista: 'estoquista',
    manicure: 'manicure',
    cabeleireira: 'cabeleireira',
    esteticista: 'esteticista',
    maquiador: 'maquiador',
    atendente: 'atendente',
    auxiliar: 'auxiliar'
  }, suffix: true

  enum :status, {
    ativo: 'ativo',
    inativo: 'inativo',
    ferias: 'ferias',
    afastado: 'afastado'
  }, suffix: true, default: :ativo

  validates :full_name, presence: true, length: { minimum: 3 }
  validates :cpf, presence: true, uniqueness: true, length: { is: 11 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :salary, numericality: { greater_than: 0 }, allow_nil: true
  validates :phone, presence: true

  before_validation :clean_cpf

  scope :active, -> { where(status: 'ativo') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_position, ->(position) { where(position: position) if position.present? }

  def clean_cpf
    self.cpf = cpf.gsub(/\D/, '') if cpf.present?
  end

  def formatted_cpf
    return '-' if cpf.blank?
    cpf.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
  end

  def formatted_phone
    return '-' if phone.blank?
    phone.gsub(/(\d{2})(\d{5})(\d{4})/, '(\1) \2-\3')
  end

  def formatted_salary
    return '-' if salary.nil?
    "R$ #{salary.to_f.round(2)}"
  end

  def years_of_service
    return 0 if admission_date.nil?
    ((Date.today - admission_date).to_i / 365.25).floor
  end

  def status_color
    case status
    when 'ativo' then 'bg-green-100 text-green-800'
    when 'inativo' then 'bg-gray-100 text-gray-800'
    when 'ferias' then 'bg-blue-100 text-blue-800'
    when 'afastado' then 'bg-yellow-100 text-yellow-800'
    else 'bg-gray-100 text-gray-800'
    end
  end
end