# frozen_string_literal: true

require "test_helper"

class ProductOutputsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @product = create(:product, :with_stock, initial_stock: 100)
    @product_output = create(:product_output, product: @product, quantity: 10)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get product_outputs_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get product_output_url(@product_output)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get product_outputs_url
    assert_response :success
  end

  test "index lista saídas de produto" do
    get product_outputs_url
    assert_select "table"
  end

  test "index filtra por produto" do
    get product_outputs_url, params: { product_id: @product.id }
    assert_response :success
  end

  test "index filtra por tipo de saída" do
    get product_outputs_url, params: { output_type: "venda" }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get product_output_url(@product_output)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_product_output_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_product_output_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria saída de produto com dados válidos" do
    product = create(:product, :with_stock, initial_stock: 100)

    assert_difference "ProductOutput.count", 1 do
      post product_outputs_url, params: {
        product_output: {
          product_id: product.id,
          quantity: 20,
          output_type: "venda",
          date_output: Date.current,
          notes: "Venda para cliente"
        }
      }
    end

    # Controller redireciona para index
    assert_redirected_to product_outputs_url
  end

  test "create reduz estoque do produto" do
    product = create(:product, :with_stock, initial_stock: 100)
    initial_quantity = product.quantity

    post product_outputs_url, params: {
      product_output: {
        product_id: product.id,
        quantity: 25,
        output_type: "venda",
        date_output: Date.current
      }
    }

    product.reload
    assert_equal initial_quantity - 25, product.quantity
  end

  test "create não cria saída maior que estoque disponível" do
    product = create(:product, :with_stock, initial_stock: 50)

    assert_no_difference "ProductOutput.count" do
      post product_outputs_url, params: {
        product_output: {
          product_id: product.id,
          quantity: 100,
          output_type: "venda",
          date_output: Date.current
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create não cria saída sem produto" do
    assert_no_difference "ProductOutput.count" do
      post product_outputs_url, params: {
        product_output: {
          product_id: nil,
          quantity: 10,
          output_type: "venda",
          date_output: Date.current
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_product_output_url(@product_output)
    assert_response :success
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy remove saída" do
    product = create(:product, :with_stock, initial_stock: 100)
    output_to_delete = create(:product_output, product: product, quantity: 10)

    assert_difference "ProductOutput.count", -1 do
      delete product_output_url(output_to_delete)
    end

    assert_redirected_to product_outputs_url
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza saída" do
    patch product_output_url(@product_output), params: {
      product_output: {
        notes: "Nota atualizada"
      }
    }

    assert_redirected_to product_output_url(@product_output)
    @product_output.reload
    assert_equal "Nota atualizada", @product_output.notes
  end

  # Nota: A validação de estoque no update é testada no model test
  # O controller segue o padrão Rails padrão de validações

  test "update permite reduzir quantidade da saída" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, quantity: 50)

    patch product_output_url(output), params: {
      product_output: {
        quantity: 30
      }
    }

    assert_redirected_to product_output_url(output)
    output.reload
    assert_equal 30, output.quantity
  end

  # ============================================
  # SEARCH PRODUCTS
  # ============================================

  test "search_products retorna produtos" do
    product1 = create(:product, name: "Shampoo Especial", active: true)
    product2 = create(:product, name: "Condicionador", active: true)

    get search_products_product_outputs_url, params: { query: "Shampoo" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.any? { |p| p["name"].include?("Shampoo") }
  end

  test "search_products com query vazia" do
    get search_products_product_outputs_url, params: { query: "" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "search_products busca por código" do
    product = create(:product, name: "Produto Teste", code: "PROD456", active: true)

    get search_products_product_outputs_url, params: { query: "PROD456" }, as: :json

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

    get list_products_product_outputs_url, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  # ============================================
  # FILTROS ADICIONAIS
  # ============================================

  test "index filtra por período" do
    product = create(:product, :with_stock, initial_stock: 100)
    old_output = create(:product_output, product: product, quantity: 5, date_output: 30.days.ago)
    recent_output = create(:product_output, product: product, quantity: 5, date_output: 5.days.ago)

    get product_outputs_url, params: {
      start_date: 10.days.ago.to_date,
      end_date: Date.current
    }

    assert_response :success
  end

  # ============================================
  # CREATE COM DATA E HORA
  # ============================================

  test "create combina data e hora" do
    product = create(:product, :with_stock, initial_stock: 100)

    post product_outputs_url, params: {
      product_output: {
        product_id: product.id,
        quantity: 10,
        output_type: "venda",
        date_output: "2026-01-25",
        date_output_time: "15:45"
      }
    }

    assert_redirected_to product_outputs_url
  end
end
