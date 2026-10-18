# frozen_string_literal: true

require "test_helper"

class Users::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user, email: "test@example.com", password: "Password123!", password_confirmation: "Password123!")
  end

  # ============================================
  # NEW - FORGOT PASSWORD FORM
  # ============================================

  test "new exibe formulário de recuperação de senha" do
    get new_user_password_url

    assert_response :success
    assert_select "form"
  end

  # ============================================
  # CREATE - SEND RESET PASSWORD INSTRUCTIONS
  # ============================================

  test "create envia instruções de recuperação de senha" do
    post user_password_url, params: {
      user: { email: @user.email }
    }

    # Deve redirecionar para a página de login após enviar instruções
    assert_redirected_to new_user_session_path
  end

  test "create com email inexistente" do
    post user_password_url, params: {
      user: { email: "nonexistent@example.com" }
    }

    # Devise retorna 422 ou exibe erro
    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT - RESET PASSWORD FORM
  # ============================================

  test "edit com token válido exibe formulário" do
    token = @user.send_reset_password_instructions

    get edit_user_password_url, params: { reset_password_token: token }

    assert_response :success
    assert_select "form"
  end

  test "edit com token inválido" do
    get edit_user_password_url, params: { reset_password_token: "invalid_token" }

    # Deve exibir a página, mas o token será validado no submit
    assert_response :success
  end

  # ============================================
  # UPDATE - RESET PASSWORD
  # ============================================

  test "update com token válido redefine senha" do
    token = @user.send_reset_password_instructions

    patch user_password_url, params: {
      user: {
        reset_password_token: token,
        password: "NewPassword123!",
        password_confirmation: "NewPassword123!"
      }
    }

    # Deve redirecionar para o dashboard após redefinir a senha
    assert_redirected_to authenticated_root_path
  end

  test "update com token inválido não redefine senha" do
    patch user_password_url, params: {
      user: {
        reset_password_token: "invalid_token",
        password: "NewPassword123!",
        password_confirmation: "NewPassword123!"
      }
    }

    assert_response :unprocessable_entity
  end

  test "update com senhas diferentes não redefine senha" do
    token = @user.send_reset_password_instructions

    patch user_password_url, params: {
      user: {
        reset_password_token: token,
        password: "NewPassword123!",
        password_confirmation: "DifferentPass123!"
      }
    }

    assert_response :unprocessable_entity
  end
end
