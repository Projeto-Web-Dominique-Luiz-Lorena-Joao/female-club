class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validação da preferência de paginação
  validates :items_per_page, inclusion: { in: [ 10, 15, 20, 25, 50 ] }, allow_nil: true
end
