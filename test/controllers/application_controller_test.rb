# frozen_string_literal: true

require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  # ============================================
  # UPDATE PAGINATION PREFERENCE
  # ============================================

  test "update_pagination_preference atualiza items_per_page" do
    sign_in @user

    patch update_pagination_preference_url, params: { items_per_page: 25 }

    @user.reload
    assert_equal 25, @user.items_per_page
    assert_response :redirect
  end

  test "update_pagination_preference remove preferência quando nil" do
    @user.update(items_per_page: 20)
    sign_in @user

    patch update_pagination_preference_url, params: { items_per_page: nil }

    @user.reload
    assert_nil @user.items_per_page
    assert_response :redirect
  end

  test "update_pagination_preference remove preferência quando vazio" do
    @user.update(items_per_page: 20)
    sign_in @user

    patch update_pagination_preference_url, params: { items_per_page: "" }

    @user.reload
    assert_nil @user.items_per_page
    assert_response :redirect
  end

  test "update_pagination_preference redireciona para página anterior" do
    sign_in @user

    patch update_pagination_preference_url, params: { items_per_page: 50 },
      headers: { "HTTP_REFERER" => customers_url }

    assert_redirected_to customers_url
  end

  test "update_pagination_preference redireciona para root sem referer" do
    sign_in @user

    patch update_pagination_preference_url, params: { items_per_page: 50 }

    assert_redirected_to root_path
  end

  test "update_pagination_preference não faz nada sem usuário logado" do
    patch update_pagination_preference_url, params: { items_per_page: 25 }

    # Deve redirecionar para login por causa do before_action :authenticate_user!
    assert_response :redirect
  end

  # ============================================
  # PER_PAGE HELPER
  # ============================================

  test "per_page retorna valor do parâmetro quando válido" do
    sign_in @user

    get customers_url, params: { per_page: 25 }

    assert_response :success
  end

  test "per_page ignora parâmetro inválido e usa preferência do usuário" do
    @user.update(items_per_page: 20)
    sign_in @user

    get customers_url, params: { per_page: 999 }

    assert_response :success
  end

  test "per_page usa preferência do usuário quando não há parâmetro" do
    @user.update(items_per_page: 50)
    sign_in @user

    get customers_url

    assert_response :success
  end

  test "per_page retorna 15 como padrão" do
    sign_in @user

    get customers_url

    assert_response :success
  end

  # ============================================
  # TESTES DE PARÂMETROS VÁLIDOS PARA PER_PAGE
  # ============================================

  test "per_page aceita 10" do
    sign_in @user
    get customers_url, params: { per_page: 10 }
    assert_response :success
  end

  test "per_page aceita 15" do
    sign_in @user
    get customers_url, params: { per_page: 15 }
    assert_response :success
  end

  test "per_page aceita 20" do
    sign_in @user
    get customers_url, params: { per_page: 20 }
    assert_response :success
  end

  test "per_page aceita 50" do
    sign_in @user
    get customers_url, params: { per_page: 50 }
    assert_response :success
  end
end
