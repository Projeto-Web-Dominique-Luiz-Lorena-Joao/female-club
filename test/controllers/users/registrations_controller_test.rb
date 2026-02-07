# frozen_string_literal: true

require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
  end

  # ============================================
  # EDIT - EDIT ACCOUNT FORM
  # ============================================

  test "edit exibe formulário de edição de conta" do
    sign_in @user

    get edit_user_registration_url

    assert_response :success
    assert_select "form"
  end

  test "edit requer autenticação" do
    get edit_user_registration_url

    assert_redirected_to new_user_session_path
  end

  # ============================================
  # UPDATE - UPDATE ACCOUNT
  # ============================================

  test "update atualiza items_per_page" do
    sign_in @user

    patch user_registration_url, params: {
      user: {
        items_per_page: 25,
        current_password: "Password123!"
      }
    }

    assert_redirected_to root_path
    @user.reload
    assert_equal 25, @user.items_per_page
  end

  test "update requer senha atual" do
    sign_in @user

    patch user_registration_url, params: {
      user: {
        items_per_page: 25
      }
    }

    # Deve falhar sem a senha atual
    assert_response :unprocessable_entity
  end

  test "update com senha atual errada não atualiza" do
    sign_in @user

    patch user_registration_url, params: {
      user: {
        items_per_page: 25,
        current_password: "wrong_password"
      }
    }

    assert_response :unprocessable_entity
  end

  test "update pode alterar senha" do
    sign_in @user

    patch user_registration_url, params: {
      user: {
        password: "NewPassword123!",
        password_confirmation: "NewPassword123!",
        current_password: "Password123!"
      }
    }

    assert_redirected_to root_path
  end

  test "update requer autenticação" do
    patch user_registration_url, params: {
      user: {
        items_per_page: 25,
        current_password: "Password123!"
      }
    }

    assert_redirected_to new_user_session_path
  end
end
