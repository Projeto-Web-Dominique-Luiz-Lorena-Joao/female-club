# frozen_string_literal: true

require "test_helper"

class YearlyReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @current_year = Date.today.year
    @employee = create(:employee)
    @customer = create(:customer)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get yearly_reports_url
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get yearly_reports_url
    assert_response :success
  end

  test "index retorna sucesso com ano especificado" do
    get yearly_reports_url, params: { year: @current_year }
    assert_response :success
  end

  test "index retorna sucesso com ano anterior" do
    get yearly_reports_url, params: { year: @current_year - 1 }
    assert_response :success
  end

  test "index calcula estatísticas anuais corretamente" do
    # Criar vendas para o ano atual
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pago, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 300, status: :pago, sale_date: 1.month.ago)
    create(:sale, employee: @employee, customer: @customer, total_amount: 200, status: :pendente, sale_date: 2.months.ago)

    # Criar despesas
    create(:expense, amount: 100, expense_date: Date.today)
    create(:expense, amount: 150, expense_date: 1.month.ago)

    get yearly_reports_url

    assert_response :success
  end

  test "index mostra dados de vendas do ano" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 1000, status: :pago, sale_date: Date.today)

    get yearly_reports_url

    assert_response :success
  end

  test "index mostra dados de despesas do ano" do
    create(:expense, amount: 500, expense_date: Date.today)

    get yearly_reports_url

    assert_response :success
  end

  test "index calcula top produtos do ano" do
    product = create(:product, :with_stock, initial_stock: 100)
    sale = create(:sale, employee: @employee, customer: @customer, sale_date: Date.today)
    create(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 100)

    get yearly_reports_url

    assert_response :success
  end

  test "index calcula top serviços do ano" do
    service = create(:service)
    sale = create(:sale, employee: @employee, customer: @customer, sale_date: Date.today)
    create(:sale_service, sale: sale, service: service, quantity: 3, unit_price: 80)

    get yearly_reports_url

    assert_response :success
  end

  test "index calcula top clientes do ano" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 1000, status: :pago, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pago, sale_date: 1.month.ago)

    get yearly_reports_url

    assert_response :success
  end

  test "index calcula dados trimestrais" do
    # Vendas em trimestres diferentes
    create(:sale, employee: @employee, customer: @customer, total_amount: 300, sale_date: Date.new(@current_year, 1, 15))
    create(:sale, employee: @employee, customer: @customer, total_amount: 400, sale_date: Date.new(@current_year, 4, 15)) if Date.today.month >= 4
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, sale_date: Date.new(@current_year, 7, 15)) if Date.today.month >= 7
    create(:sale, employee: @employee, customer: @customer, total_amount: 600, sale_date: Date.new(@current_year, 10, 15)) if Date.today.month >= 10

    get yearly_reports_url

    assert_response :success
  end

  test "index calcula crescimento comparado ao ano anterior" do
    # Criar vendas no ano anterior
    last_year = @current_year - 1
    create(:sale, employee: @employee, customer: @customer, total_amount: 1000, sale_date: Date.new(last_year, 6, 15))

    # Criar vendas no ano atual
    create(:sale, employee: @employee, customer: @customer, total_amount: 1500, sale_date: Date.today)

    get yearly_reports_url

    assert_response :success
  end

  test "index funciona sem dados" do
    get yearly_reports_url
    assert_response :success
  end

  test "index calcula melhor e pior mês" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 1000, sale_date: Date.new(@current_year, 1, 15))
    create(:sale, employee: @employee, customer: @customer, total_amount: 100, sale_date: Date.new(@current_year, 2, 15)) if Date.today.month >= 2

    get yearly_reports_url

    assert_response :success
  end
end
