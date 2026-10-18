class User < ApplicationRecord
  # SEGURANÇA: Módulos Devise com lockable e timeoutable habilitados
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable, :trackable

  # Validação da preferência de paginação
  validates :items_per_page, inclusion: { in: [ 10, 15, 20, 25, 50 ] }, allow_nil: true

  # SEGURANÇA: Validação de senha forte
  validate :password_complexity

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :admins, -> { where(admin: true) }

  def admin?
    admin
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_inactive
  end

  def display_name
    name.presence || email
  end

  def status_label
    active? ? "Ativo" : "Cancelado"
  end

  def status_badge_class
    active? ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"
  end

  private

  def password_complexity
    return if password.blank?

    unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$/)
      errors.add :password, "deve ter no mínimo 8 caracteres, com letras maiúsculas e minúsculas, números e pelo menos 1 caractere especial"
    end
  end
end
