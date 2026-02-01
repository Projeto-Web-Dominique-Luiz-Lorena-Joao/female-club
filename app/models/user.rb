class User < ApplicationRecord
  # SEGURANÇA: Módulos Devise com lockable e timeoutable habilitados
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable, :trackable

  # Validação da preferência de paginação
  validates :items_per_page, inclusion: { in: [ 10, 15, 20, 25, 50 ] }, allow_nil: true

  # SEGURANÇA: Validação de senha forte (mínimo 8 caracteres, pelo menos 1 letra e 1 número)
  validate :password_complexity

  private

  def password_complexity
    return if password.blank?

    unless password.match?(/^(?=.*[A-Za-z])(?=.*\d).{8,}$/)
      errors.add :password, 'deve ter no mínimo 8 caracteres e conter pelo menos uma letra e um número'
    end
  end
end
