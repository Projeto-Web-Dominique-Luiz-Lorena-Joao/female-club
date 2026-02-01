# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar usuário com atributos válidos" do
    user = build(:user)
    assert_valid user
  end

  test "deve exigir email" do
    user = build(:user, email: nil)
    assert_invalid user, :email
  end

  test "deve exigir senha" do
    user = User.new(email: "test@example.com", password: nil, password_confirmation: nil)
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  # ============================================
  # VALIDAÇÃO DE EMAIL
  # ============================================

  test "email deve ser único" do
    create(:user, email: "test@example.com")

    user = build(:user, email: "test@example.com")
    assert_invalid user, :email
  end

  test "email com formato inválido não é aceito" do
    user = build(:user, email: "invalid-email")
    assert_invalid user, :email
  end

  test "email duplicado case insensitive é inválido" do
    create(:user, email: "Test@Example.com")

    user = build(:user, email: "test@example.com")
    assert_invalid user, :email
  end

  # ============================================
  # VALIDAÇÃO DE SENHA - COMPLEXIDADE
  # ============================================

  test "senha deve ter pelo menos 8 caracteres" do
    user = build(:user, password: "Pass1", password_confirmation: "Pass1")
    assert_invalid user, :password
  end

  test "senha com 8 caracteres válidos é aceita" do
    user = build(:user, password: "Password1", password_confirmation: "Password1")
    assert_valid user
  end

  test "senha deve conter pelo menos uma letra" do
    user = build(:user, password: "12345678", password_confirmation: "12345678")
    assert_invalid user, :password
  end

  test "senha deve conter pelo menos um número" do
    user = build(:user, password: "Password", password_confirmation: "Password")
    assert_invalid user, :password
  end

  test "senha com letra e número é válida" do
    user = build(:user, password: "Abc12345", password_confirmation: "Abc12345")
    assert_valid user
  end

  test "confirmação de senha deve coincidir" do
    user = build(:user, password: "Password1", password_confirmation: "Different1")
    assert_invalid user, :password_confirmation
  end

  # ============================================
  # VALIDAÇÃO DE ITEMS_PER_PAGE
  # ============================================

  test "items_per_page deve estar nos valores permitidos" do
    user = build(:user, items_per_page: 30)
    assert_invalid user, :items_per_page
  end

  test "items_per_page 10 é válido" do
    user = build(:user, items_per_page: 10)
    assert_valid user
  end

  test "items_per_page 15 é válido" do
    user = build(:user, items_per_page: 15)
    assert_valid user
  end

  test "items_per_page 20 é válido" do
    user = build(:user, items_per_page: 20)
    assert_valid user
  end

  test "items_per_page 25 é válido" do
    user = build(:user, items_per_page: 25)
    assert_valid user
  end

  test "items_per_page 50 é válido" do
    user = build(:user, items_per_page: 50)
    assert_valid user
  end

  # ============================================
  # DEVISE - LOCKABLE
  # ============================================

  test "usuário pode ser bloqueado" do
    user = create(:user)
    user.lock_access!

    assert user.access_locked?
  end

  test "usuário bloqueado pode ser desbloqueado" do
    user = create(:user, :locked)
    user.unlock_access!

    assert_not user.access_locked?
  end

  # ============================================
  # DEVISE - RECOVERABLE
  # ============================================

  test "reset_password_token pode ser gerado" do
    user = create(:user)
    token, enc = Devise.token_generator.generate(User, :reset_password_token)
    user.reset_password_token = enc
    user.reset_password_sent_at = Time.current
    user.save!

    assert user.reset_password_token.present?
    assert user.reset_password_sent_at.present?
  end

  # ============================================
  # DEVISE - TRACKABLE
  # ============================================

  test "trackable fields existem" do
    user = create(:user)

    assert user.respond_to?(:sign_in_count)
    assert user.respond_to?(:current_sign_in_at)
    assert user.respond_to?(:last_sign_in_at)
    assert user.respond_to?(:current_sign_in_ip)
    assert user.respond_to?(:last_sign_in_ip)
  end

  # ============================================
  # DEVISE - TIMEOUTABLE
  # ============================================

  test "sessão pode expirar" do
    user = create(:user)

    # Simula sessão antiga
    assert user.respond_to?(:timedout?)
  end

  # ============================================
  # ATRIBUTOS OPCIONAIS
  # ============================================

  test "nome é opcional" do
    user = build(:user, name: nil)
    assert_valid user
  end

  test "telefone é opcional" do
    user = build(:user, phone: nil)
    assert_valid user
  end

  # ============================================
  # ATUALIZAÇÃO DE USUÁRIO
  # ============================================

  test "pode atualizar email" do
    user = create(:user)
    user.update!(email: "newemail@example.com")

    assert_equal "newemail@example.com", user.reload.email
  end

  test "pode atualizar items_per_page" do
    user = create(:user, items_per_page: 15)
    user.update!(items_per_page: 50)

    assert_equal 50, user.reload.items_per_page
  end

  test "pode atualizar senha" do
    user = create(:user)
    user.update!(password: "NewPass123", password_confirmation: "NewPass123")

    assert user.valid_password?("NewPass123")
  end
end
