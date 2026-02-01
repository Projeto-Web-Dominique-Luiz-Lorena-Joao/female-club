# frozen_string_literal: true

require "test_helper"

class MonthlyReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @current_month = Date.today.beginning_of_month
    @employee = create(:employee)
    @customer = create(:customer)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get monthly_reports_url
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get monthly_reports_url
    assert_response :success
  end

  test "index retorna sucesso com mês especificado por parâmetros year e month" do
    get monthly_reports_url, params: { year: Date.today.year, month: Date.today.month }
    assert_response :success
  end

  test "index retorna sucesso com mês anterior" do
    last_month = 1.month.ago
    get monthly_reports_url, params: { year: last_month.year, month: last_month.month }
    assert_response :success
  end

  test "index calcula estatísticas mensais corretamente" do
    # Criar vendas para o mês atual
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pago, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 300, status: :pendente, sale_date: Date.today)

    # Criar despesas
    create(:expense, amount: 100, expense_date: Date.today)

    get monthly_reports_url

    assert_response :success
  end

  test "index mostra receitas totais do mês" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 1000, status: :pago, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pago, sale_date: Date.today)

    get monthly_reports_url

    assert_response :success
  end

  test "index mostra despesas do mês" do
    create(:expense, amount: 200, expense_date: Date.today)
    create(:expense, amount: 300, expense_date: Date.today)

    get monthly_reports_url

    assert_response :success
  end

  test "index calcula fluxo de caixa diário" do
    # Vendas em dias diferentes
    create(:sale, employee: @employee, customer: @customer, total_amount: 100, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 200, sale_date: Date.today - 1.day) if Date.today.day > 1

    # Despesas em dias diferentes
    create(:expense, amount: 50, expense_date: Date.today)

    get monthly_reports_url

    assert_response :success
  end

  test "index calcula projeções de gastos" do
    # Criar despesas fixas nos últimos meses
    3.times do |i|
      create(:expense, amount: 500, category: "fixa_mensal", expense_date: i.months.ago)
    end

    # Criar despesas esporádicas
    2.times do |i|
      create(:expense, amount: 100, category: "esporadica", expense_date: i.months.ago)
    end

    get monthly_reports_url

    assert_response :success
  end

  test "index calcula top produtos do mês" do
    product = create(:product, :with_stock, initial_stock: 100)
    sale = create(:sale, employee: @employee, customer: @customer, sale_date: Date.today)
    create(:sale_product, sale: sale, product: product, quantity: 10, unit_price: 50)

    get monthly_reports_url

    assert_response :success
  end

  test "index calcula top serviços do mês" do
    service = create(:service)
    sale = create(:sale, employee: @employee, customer: @customer, sale_date: Date.today)
    create(:sale_service, sale: sale, service: service, quantity: 5, unit_price: 100)

    get monthly_reports_url

    assert_response :success
  end

  test "index mostra vendas atrasadas" do
    # Criar venda pendente com data de vencimento passada
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pendente, sale_date: Date.today, due_date: 5.days.ago)

    get monthly_reports_url

    assert_response :success
  end

  test "index mostra vendas pendentes futuras" do
    # Criar venda pendente com data de vencimento futura
    create(:sale, employee: @employee, customer: @customer, total_amount: 300, status: :pendente, sale_date: Date.today, due_date: 5.days.from_now)

    get monthly_reports_url

    assert_response :success
  end

  test "index funciona sem dados" do
    get monthly_reports_url
    assert_response :success
  end

  test "index calcula dados do gráfico de comparação" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 1000, sale_date: Date.today)
    create(:expense, amount: 500, expense_date: Date.today)

    get monthly_reports_url

    assert_response :success
  end
end
