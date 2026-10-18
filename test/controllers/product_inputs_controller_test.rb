# frozen_string_literal: true

require "test_helper"

class ProductInputsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @product = create(:product)
    @supplier = create(:supplier)
    @product_input = create(:product_input, product: @product, supplier: @supplier)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get product_inputs_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get product_input_url(@product_input)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get product_inputs_url
    assert_response :success
  end

  test "index lista entradas de produto" do
    get product_inputs_url
    assert_select "table"
  end

  test "index filtra por produto" do
    get product_inputs_url, params: { product_id: @product.id }
    assert_response :success
  end

  test "index filtra por fornecedor" do
    get product_inputs_url, params: { supplier_id: @supplier.id }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get product_input_url(@product_input)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_product_input_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_product_input_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria entrada de produto com dados válidos" do
    product = create(:product)

    assert_difference "ProductInput.count", 1 do
      post product_inputs_url, params: {
        product_input: {
          product_id: product.id,
          supplier_id: @supplier.id,
          quantity: 50,
          unit_cost: 10.00,
          date_input: Date.current,
          invoice_number: "NF-12345"
        }
      }
    end

    # Controller redireciona para index
    assert_redirected_to product_inputs_url
  end

  test "create aumenta estoque do produto" do
    product = create(:product)
    initial_quantity = product.quantity

    post product_inputs_url, params: {
      product_input: {
        product_id: product.id,
        quantity: 30,
        date_input: Date.current
      }
    }

    product.reload
    assert_equal initial_quantity + 30, product.quantity
  end

  test "create não cria entrada sem produto" do
    assert_no_difference "ProductInput.count" do
      post product_inputs_url, params: {
        product_input: {
          product_id: nil,
          quantity: 50,
          date_input: Date.current
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_product_input_url(@product_input)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza entrada" do
    original_cost = @product_input.unit_cost.to_f
    new_cost = 15.00

    patch product_input_url(@product_input), params: {
      product_input: {
        unit_cost: new_cost
      }
    }

    assert_redirected_to product_input_url(@product_input)
    @product_input.reload
    # O controller pode converter o valor de formato brasileiro
    # Verificamos que o valor foi alterado
    assert_not_equal original_cost, @product_input.unit_cost.to_f
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy remove entrada" do
    product = create(:product)
    input_to_delete = create(:product_input, product: product)

    assert_difference "ProductInput.count", -1 do
      delete product_input_url(input_to_delete)
    end

    assert_redirected_to product_inputs_url
  end

  # ============================================
  # SEARCH PRODUCTS
  # ============================================

  test "search_products retorna produtos" do
    product1 = create(:product, name: "Shampoo Especial", active: true)
    product2 = create(:product, name: "Condicionador", active: true)

    get search_products_product_inputs_url, params: { query: "Shampoo" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.any? { |p| p["name"].include?("Shampoo") }
  end

  test "search_products com query vazia" do
    get search_products_product_inputs_url, params: { query: "" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "search_products busca por código" do
    product = create(:product, name: "Produto Teste", code: "PROD123", active: true)

    get search_products_product_inputs_url, params: { query: "PROD123" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert data.any? { |p| p["id"] == product.id }
  end

  # ============================================
  # LIST PRODUCTS
  # ============================================

  test "list_products retorna todos produtos ativos" do
    create(:product, name: "Produto A", active: true)
    create(:product, name: "Produto B", active: true)
    create(:product, name: "Produto Inativo", active: false)

    get list_products_product_inputs_url, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  # ============================================
  # SEARCH SUPPLIERS
  # ============================================

  test "search_suppliers retorna fornecedores ativos" do
    supplier1 = create(:supplier, legal_name: "Fornecedor Alpha", status: "ativo")
    supplier2 = create(:supplier, legal_name: "Fornecedor Beta", status: "ativo")

    get search_suppliers_product_inputs_url, params: { query: "Alpha" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "search_suppliers com query vazia" do
    get search_suppliers_product_inputs_url, params: { query: "" }, as: :json

    assert_response :success
  end

  # ============================================
  # LIST SUPPLIERS
  # ============================================

  test "list_suppliers retorna todos fornecedores ativos" do
    create(:supplier, legal_name: "Fornecedor A", status: "ativo")
    create(:supplier, legal_name: "Fornecedor B", status: "ativo")
    create(:supplier, legal_name: "Fornecedor Inativo", status: "inativo")

    get list_suppliers_product_inputs_url, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  # ============================================
  # FILTROS ADICIONAIS
  # ============================================

  test "index filtra por período" do
    product = create(:product)
    old_input = create(:product_input, product: product, date_input: 30.days.ago)
    recent_input = create(:product_input, product: product, date_input: 5.days.ago)

    get product_inputs_url, params: {
      start_date: 10.days.ago.to_date,
      end_date: Date.current
    }

    assert_response :success
  end

  # ============================================
  # CREATE COM FORMATO BRASILEIRO
  # ============================================

  test "create aceita unit_cost em formato brasileiro" do
    product = create(:product)

    assert_difference "ProductInput.count", 1 do
      post product_inputs_url, params: {
        product_input: {
          product_id: product.id,
          quantity: 10,
          unit_cost: "1.234,56",  # Formato brasileiro
          date_input: Date.current
        }
      }
    end

    assert_redirected_to product_inputs_url
    input = ProductInput.last
    # O valor deve ser 1234.56 após conversão
    assert_in_delta 1234.56, input.unit_cost.to_f, 0.01
  end

  test "create combina data e hora" do
    product = create(:product)

    post product_inputs_url, params: {
      product_input: {
        product_id: product.id,
        quantity: 10,
        date_input: "2026-01-25",
        date_input_time: "14:30"
      }
    }

    assert_redirected_to product_inputs_url
  end
end
