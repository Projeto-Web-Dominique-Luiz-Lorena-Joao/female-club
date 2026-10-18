# frozen_string_literal: true

require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @supplier = create(:supplier)
    @product = create(:product, supplier: @supplier)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get products_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get product_url(@product)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get products_url
    assert_response :success
  end

  test "index lista produtos" do
    get products_url
    assert_select "table"
  end

  test "index filtra por categoria" do
    get products_url, params: { category: "beleza_cosmeticos" }
    assert_response :success
  end

  test "index filtra por status de estoque" do
    get products_url, params: { stock_status: "em_estoque" }
    assert_response :success
  end

  test "index busca por termo" do
    get products_url, params: { search: @product.name }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get product_url(@product)
    assert_response :success
  end

  test "show exibe detalhes do produto" do
    get product_url(@product)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_product_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_product_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria produto com dados válidos" do
    assert_difference "Product.count", 1 do
      post products_url, params: {
        product: {
          name: "Novo Produto",
          brand: "Marca X",
          category: "beleza_cosmeticos",
          sale_price: 99.90,
          min_stock: 10,
          unit: "unidade",
          supplier_id: @supplier.id
        }
      }
    end

    assert_redirected_to product_url(Product.last)
  end

  test "create não cria produto sem nome" do
    assert_no_difference "Product.count" do
      post products_url, params: {
        product: {
          name: nil,
          min_stock: 10
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_product_url(@product)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza produto" do
    patch product_url(@product), params: {
      product: {
        name: "Nome Atualizado"
      }
    }

    assert_redirected_to product_url(@product)
    @product.reload
    assert_equal "Nome Atualizado", @product.name
  end

  test "update pode alterar preço" do
    patch product_url(@product), params: {
      product: {
        sale_price: 199.90
      }
    }

    assert_redirected_to product_url(@product)
    @product.reload
    assert_equal 199.90, @product.sale_price.to_f
  end

  test "update pode alterar estoque mínimo" do
    patch product_url(@product), params: {
      product: {
        min_stock: 25
      }
    }

    assert_redirected_to product_url(@product)
    @product.reload
    assert_equal 25, @product.min_stock
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy remove produto" do
    product_to_delete = create(:product)

    assert_difference "Product.count", -1 do
      delete product_url(product_to_delete)
    end

    assert_redirected_to products_url
  end

  # ============================================
  # FILTROS ADICIONAIS
  # ============================================

  test "index filtra por active true" do
    active_product = create(:product, active: true)
    inactive_product = create(:product, active: false)

    get products_url, params: { active: "true" }
    assert_response :success
  end

  test "index filtra por active false" do
    active_product = create(:product, active: true)
    inactive_product = create(:product, active: false)

    get products_url, params: { active: "false" }
    assert_response :success
  end

  test "index filtra por low_stock" do
    normal_product = create(:product, :with_stock, initial_stock: 100, min_stock: 10)
    low_stock_product = create(:product, :with_stock, initial_stock: 5, min_stock: 50, stock_status: :baixo)

    get products_url, params: { low_stock: "true" }
    assert_response :success
  end

  test "index filtra por stock_status especifico" do
    critical_product = create(:product, :critical_stock, name: "Produto Critico Unico")
    low_product = create(:product, :low_stock, name: "Produto Baixo Unico")
    out_of_stock_product = create(:product, :out_of_stock, name: "Produto Zerado Unico")

    get products_url, params: { stock_status: "critico" }
    assert_response :success
    assert_match critical_product.name, response.body
    assert_no_match(/#{low_product.name}/, response.body)
    assert_no_match(/#{out_of_stock_product.name}/, response.body)

    get products_url, params: { stock_status: "fora_de_estoque" }
    assert_response :success
    assert_match out_of_stock_product.name, response.body
    assert_no_match(/#{critical_product.name}/, response.body)
  end

  # ============================================
  # UPDATE COM ERRO
  # ============================================

  test "update com dados inválidos retorna erro" do
    patch product_url(@product), params: {
      product: {
        name: ""  # Nome vazio é inválido
      }
    }

    assert_response :unprocessable_entity
  end
end
