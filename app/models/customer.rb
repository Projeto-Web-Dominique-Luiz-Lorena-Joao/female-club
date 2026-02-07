class Customer < ApplicationRecord
  has_many :sales, foreign_key: :customer_id, dependent: :destroy
  belongs_to :guarantor, optional: true
  has_many :service_appointments, dependent: :destroy
  # has_many :receivables, dependent: :destroy
  # has_many :incomes, dependent: :nullify


  validates :full_name, presence: true, length: { minimum: 3 }
  validates :cpf, uniqueness: true, allow_blank: true
  validate :cpf_must_be_valid
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "não é válido" }, uniqueness: { case_sensitive: false, message: "já está em uso" }, allow_blank: true
  validates :phone_number, length: { minimum: 10 }, allow_blank: true

  before_validation :clean_cpf


  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { joins(:sales).where("sales.created_at >= ?", 6.months.ago).distinct }
  scope :vip, -> { joins(:sales).group("customers.id").having("COUNT(sales.id) >= 5") }


  def clean_cpf
    self.cpf = cpf.gsub(/\D/, "") if cpf.present?
  end

  def formatted_cpf
    return "-" if cpf.blank?
    cpf.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
  end

  def formatted_phone
    return "-" if phone_number.blank?
    phone_number.gsub(/(\d{2})(\d{5})(\d{4})/, '(\1) \2-\3')
  end

  def formatted_birth_date
    return "-" if birth_date.nil?
    I18n.l(birth_date, format: :short) rescue birth_date.strftime("%d/%m/%Y")
  end

  def age
    return nil if birth_date.nil?
    ((Date.today - birth_date).to_i / 365.25).floor
  end

  def total_purchases
    sales.where.not(status: "cancelado").sum(:total_amount)
  end

  def last_purchase_date
    sales.where.not(status: "cancelado").maximum(:sale_date)
  end

  def purchases_count
    sales.where.not(status: "cancelado").count
  end

  private

  def cpf_must_be_valid
    return if cpf.blank?

    unless CPF.valid?(cpf)
      errors.add(:cpf, "não é válido")
    end
  end
end
