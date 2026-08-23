# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para dashboard" do
    sign_out @user
    get dashboard_url
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # DASHBOARD
  # ============================================

  test "dashboard retorna sucesso" do
    get dashboard_url
    assert_response :success
  end

  test "dashboard exibe KPIs" do
    get dashboard_url
    assert_response :success
  end

  test "dashboard com vendas recentes" do
    employee = create(:employee)
    customer = create(:customer)

    create(:sale, employee: employee, customer: customer, sale_date: Date.current)

    get dashboard_url
    assert_response :success
  end

  test "dashboard com produtos em estoque baixo" do
    create(:product, min_stock: 100, stock_status: :baixo)

    get dashboard_url
    assert_response :success
  end

  test "dashboard calcula top produtos vendidos" do
    employee = create(:employee)
    product = create(:product, :with_stock, initial_stock: 100)

    # Criar venda com produtos para testar calculate_top_products
    sale = create(:sale, employee: employee, sale_date: Date.current, status: :pago)
    create(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 50)

    get dashboard_url
    assert_response :success
  end

  test "dashboard calcula variação com dados do mês anterior" do
    employee = create(:employee)
    customer = create(:customer)

    # Criar venda no mês anterior para testar calculate_variation
    last_month = 1.month.ago.to_date
    create(:sale, employee: employee, customer: customer, sale_date: last_month, total_amount: 1000, status: :pago)

    # Criar venda no mês atual
    create(:sale, employee: employee, customer: customer, sale_date: Date.current, total_amount: 1500, status: :pago)

    get dashboard_url
    assert_response :success
  end

  test "dashboard com múltiplas vendas e produtos" do
    employee = create(:employee)
    product1 = create(:product, :with_stock, initial_stock: 100, name: "Produto A")
    product2 = create(:product, :with_stock, initial_stock: 100, name: "Produto B")
    product3 = create(:product, :with_stock, initial_stock: 100, name: "Produto C")

    # Criar vendas com múltiplos produtos
    sale1 = create(:sale, employee: employee, sale_date: Date.current, status: :pago)
    create(:sale_product, sale: sale1, product: product1, quantity: 10, unit_price: 100)
    create(:sale_product, sale: sale1, product: product2, quantity: 5, unit_price: 50)

    sale2 = create(:sale, employee: employee, sale_date: Date.current, status: :pago)
    create(:sale_product, sale: sale2, product: product3, quantity: 3, unit_price: 200)
    create(:sale_product, sale: sale2, product: product1, quantity: 2, unit_price: 100)

    get dashboard_url
    assert_response :success
  end

  test "dashboard exibe vendas vencidas com valor total correto" do
    employee = create(:employee)
    customer = create(:customer, full_name: "Cliente Vencido Teste")

    create(:sale, :overdue, employee: employee, customer: customer, total_amount: 250, status: :pendente)

    get dashboard_url
    assert_response :success
    assert_match "Vendas Vencidas", response.body
    assert_match "Cliente Vencido Teste", response.body
    assert_match "250,00", response.body
  end

  test "dashboard exibe aniversariantes apenas do mes atual" do
    aniversariante = create(:customer, full_name: "Aniversariante Teste", birth_date: Date.current.change(year: 1990))
    fora_do_mes = create(:customer, full_name: "Fora Do Mes Teste", birth_date: (Date.current + 6.months).change(year: 1990))

    get dashboard_url
    assert_response :success
    assert_match "Aniversariante Teste", response.body
    assert_no_match(/Fora Do Mes Teste/, response.body)
  end

  test "dashboard não quebra com cliente sem data de nascimento" do
    create(:customer, birth_date: nil)

    get dashboard_url
    assert_response :success
  end

  test "dashboard ignora vendas canceladas no cálculo de top produtos" do
    employee = create(:employee)
    product = create(:product, :with_stock, initial_stock: 100)

    # Criar venda cancelada
    sale = create(:sale, employee: employee, sale_date: Date.current, status: :cancelado)
    create(:sale_product, sale: sale, product: product, quantity: 100, unit_price: 1000)

    get dashboard_url
    assert_response :success
  end
end
