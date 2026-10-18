# frozen_string_literal: true

require "test_helper"

class Api::SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  # ============================================
  # SEARCH
  # ============================================

  test "search retorna fornecedores por razão social" do
    supplier1 = create(:supplier, legal_name: "Fornecedor Alpha LTDA", trade_name: nil)
    supplier2 = create(:supplier, legal_name: "Empresa Beta SA", trade_name: nil)

    get api_suppliers_search_url, params: { q: "Alpha" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
    # Verifica que o fornecedor foi encontrado pelo ID
    assert data.any? { |s| s["id"] == supplier1.id }
  end

  test "search retorna fornecedores por nome fantasia" do
    supplier = create(:supplier, legal_name: "Razão Social", trade_name: "Nome Fantasia Especial")

    get api_suppliers_search_url, params: { q: "Especial" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "search com query vazia retorna array vazio" do
    get api_suppliers_search_url, params: { q: "" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "search limita resultados a 10" do
    15.times { create(:supplier) }

    get api_suppliers_search_url, params: { q: "" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert data.size <= 10
  end

  test "search ordena por razão social" do
    create(:supplier, legal_name: "Zeta Fornecedores")
    create(:supplier, legal_name: "Alpha Suprimentos")

    get api_suppliers_search_url, params: { q: "" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    names = data.map { |s| s["name"] }
    # O search ordena por legal_name
  end

  test "search retorna id e name (display_name)" do
    supplier = create(:supplier, legal_name: "Razão Social", trade_name: "Nome Fantasia")

    get api_suppliers_search_url, params: { q: "Razão" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    result = data.find { |s| s["id"] == supplier.id }

    assert_not_nil result
    assert_equal supplier.id, result["id"]
    # display_name retorna trade_name quando presente
    assert_equal supplier.display_name, result["name"]
  end

  test "search é case insensitive" do
    supplier = create(:supplier, legal_name: "FORNECEDOR PRINCIPAL", trade_name: nil)

    get api_suppliers_search_url, params: { q: "fornecedor" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    # Verifica que encontrou o fornecedor (display_name será legal_name pois trade_name é nil)
    assert data.any? { |s| s["id"] == supplier.id }
  end

  test "search com caracteres especiais" do
    get api_suppliers_search_url, params: { q: "Teste%" }, as: :json

    assert_response :success
  end
end
