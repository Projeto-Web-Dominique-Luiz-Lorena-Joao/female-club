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
  validates :position, presence: true, inclusion: { in: positions.keys }


  before_validation :clean_cpf
  before_validation :clean_phone


  scope :active, -> { where(status: ['ativo', 'ferias']) }
  scope :on_payroll, -> { where(status: ['ativo', 'ferias']) }
  scope :working, -> { where(status: 'ativo') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_position, ->(position) { where(position: position) if position.present? }

  def clean_cpf
    self.cpf = cpf.gsub(/\D/, '') if cpf.present?
  end

  def clean_phone
  self.phone = phone.gsub(/\D/, '') if phone.present?
  end

  def formatted_cpf
    return '-' if cpf.blank?
    cpf.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
  end


  def formatted_phone
    return '-' if phone.blank?
    clean = phone.gsub(/\D/, '')

    if clean.length == 11
      clean.gsub(/(\d{2})(\d{5})(\d{4})/, '(\1) \2-\3')  # Celular
    elsif clean.length == 10
      clean.gsub(/(\d{2})(\d{4})(\d{4})/, '(\1) \2-\3')  # Fixo
    else
      phone
    end
  end

  def formatted_salary
    return '-' if salary.nil?
    "R$ #{salary.to_f.round(2)}"
  end

  def years_of_service
    return 0 if admission_date.nil?
    ((Date.today - admission_date).to_i / 365.25).floor
  end

  def formatted_admission_time
    return '-' if admission_date.nil?

    days_diff = (Date.today - admission_date).to_i
    years = (days_diff / 365.25).floor
    remaining_days = days_diff % 365
    months = (remaining_days / 30.44).floor

    if years > 0
      if months > 0
        "#{years} ano#{years > 1 ? 's' : ''} e #{months} mês#{months > 1 ? 'es' : ''}"
      else
        "#{years} ano#{years > 1 ? 's' : ''}"
      end
    elsif months > 0
      "#{months} mês#{months > 1 ? 'es' : ''}"
    else
      "#{days_diff} dia#{days_diff > 1 ? 's' : ''}"
    end
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


  def on_payroll?
    ['ativo', 'ferias'].include?(status)
  end
end