# frozen_string_literal: true

class AccessRequest < ApplicationRecord
  attr_accessor :password, :password_confirmation

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validates :password, presence: true, on: :create
  validates :password_confirmation, presence: true, on: :create

  validate :password_complexity, on: :create
  validate :passwords_match, on: :create

  before_validation :encrypt_raw_password, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def status_badge_class
    case status
    when "pending" then "bg-yellow-100 text-yellow-800"
    when "approved" then "bg-green-100 text-green-800"
    when "rejected" then "bg-red-100 text-red-800"
    end
  end

  def status_label
    case status
    when "pending" then "Pendente"
    when "approved" then "Aprovada"
    when "rejected" then "Rejeitada"
    end
  end

  private

  def encrypt_raw_password
    return if password.blank?

    self.encrypted_password = Devise::Encryptor.digest(User, password)
  end

  def password_complexity
    return if password.blank?

    unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$/)
      errors.add :password, "deve ter no mínimo 8 caracteres, com letras maiúsculas e minúsculas, números e pelo menos 1 caractere especial"
    end
  end

  def passwords_match
    return if password.blank?

    if password != password_confirmation
      errors.add :password_confirmation, "não corresponde à senha"
    end
  end
end
