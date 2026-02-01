class Guarantor < ApplicationRecord

  has_one :customer, dependent: :nullify

  enum :relationship, {
    pai: "pai",
    mae: "mãe",
    irmao: "irmão(a)",
    esposo: "esposo(a)",
    avo: "avô(a)",
    tio: "tio(a)",
    primo: "primo(a)",
    amigo: "amigo(a)",
    outro: "outro"
  }

  enum :status, {
    ativo: 'ativo',
    inativo: 'inativo'
  }, default: :ativo

  validates :full_name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :cpf, allow_blank: true, uniqueness: true
  validate :cpf_must_be_valid
  validates :phone, format: { with: /\A\d{10,11}\z/, message: "deve conter 10 ou 11 dígitos" },
                    allow_blank: true
  validates :relationship, length: { maximum: 50 }, allow_blank: true
  validates :status, presence: true, inclusion: { in: statuses.keys, message: "deve ser 'ativo' ou 'inativo'" }

  before_validation :normalize_cpf
  before_validation :normalize_phone

  scope :with_cpf, -> { where.not(cpf: nil) }
  scope :with_phone, -> { where.not(phone: nil) }
  scope :by_relationship, ->(relationship) { where(relationship: relationship) }
  scope :recent, -> { order(created_at: :desc) }

  def formatted_cpf
    return nil unless cpf.present?
    cpf.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
  end

  def formatted_phone
    return nil unless phone.present?
    if phone.length == 11
      phone.gsub(/(\d{2})(\d{5})(\d{4})/, '(\1) \2-\3')
    elsif phone.length == 10
      phone.gsub(/(\d{2})(\d{4})(\d{4})/, '(\1) \2-\3')
    else
      phone
    end
  end

  private

  def normalize_cpf
    self.cpf = cpf.to_s.gsub(/\D/, '') if cpf.present?
    self.cpf = nil if cpf.blank?
  end

  def normalize_phone
    self.phone = phone.to_s.gsub(/\D/, '') if phone.present?
    self.phone = nil if phone.blank?
  end

  def cpf_must_be_valid
    return if cpf.blank?

    unless CPF.valid?(cpf)
      errors.add(:cpf, "não é válido")
    end
  end
end