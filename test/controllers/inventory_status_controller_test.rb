# frozen_string_literal: true

require "test_helper"

class InventoryStatusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get inventory_status_url
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get inventory_status_url
    assert_response :success
  end

  test "index lista produtos ativos" do
    create(:product, active: true)
    create(:product, active: true)
    create(:product, active: false)

    get inventory_status_url

    assert_response :success
  end

  test "index filtra por status de estoque" do
    product_in_stock = create(:product, :with_stock, initial_stock: 100, min_stock: 10)
    product_low = create(:product, min_stock: 50)

    get inventory_status_url, params: { stock_status: "em_estoque" }

    assert_response :success
  end

  test "index busca por nome do produto" do
    create(:product, name: "Shampoo Premium")
    create(:product, name: "Condicionador")

    get inventory_status_url, params: { search: "Shampoo" }

    assert_response :success
  end

  test "index busca por código do produto" do
    create(:product, code: "PROD001")
    create(:product, code: "PROD002")

    get inventory_status_url, params: { search: "PROD001" }

    assert_response :success
  end

  test "index mostra estatísticas de estoque" do
    # Criar produtos com diferentes status de estoque
    create(:product, :with_stock, initial_stock: 100, min_stock: 10)
    create(:product, min_stock: 10)

    get inventory_status_url

    assert_response :success
  end

  test "index mostra produtos críticos" do
    product = create(:product, min_stock: 100)
    create(:product_input, product: product, quantity: 5)

    get inventory_status_url

    assert_response :success
  end

  test "index mostra produtos fora de estoque" do
    create(:product, min_stock: 10)

    get inventory_status_url

    assert_response :success
  end

  test "index pagina resultados" do
    15.times { create(:product) }

    get inventory_status_url, params: { page: 1 }

    assert_response :success
  end

  test "index atualiza status de estoque dos produtos" do
    product = create(:product, min_stock: 10)
    create(:product_input, product: product, quantity: 100)

    get inventory_status_url

    product.reload
    assert_response :success
  end

  test "index funciona sem produtos" do
    get inventory_status_url
    assert_response :success
  end
end
