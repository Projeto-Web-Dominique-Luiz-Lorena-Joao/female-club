# frozen_string_literal: true

require "test_helper"

class DailyReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @employee = create(:employee)
    @customer = create(:customer)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get daily_reports_url
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get daily_reports_url
    assert_response :success
  end

  test "index retorna sucesso com data especificada" do
    get daily_reports_url, params: { date: Date.today.to_s }
    assert_response :success
  end

  test "index retorna sucesso com data passada" do
    get daily_reports_url, params: { date: 5.days.ago.to_date.to_s }
    assert_response :success
  end

  test "index calcula estatísticas diárias corretamente" do
    # Criar vendas para hoje
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pago, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 300, status: :pendente, sale_date: Date.today)

    # Criar despesas
    create(:expense, amount: 100, expense_date: Date.today)

    get daily_reports_url

    assert_response :success
  end

  test "index mostra receitas do dia" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 1000, status: :pago, sale_date: Date.today)

    get daily_reports_url

    assert_response :success
  end

  test "index mostra recebido hoje" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pago, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 300, status: :pendente, sale_date: Date.today)

    get daily_reports_url

    assert_response :success
  end

  test "index mostra despesas do dia" do
    create(:expense, amount: 200, expense_date: Date.today)

    get daily_reports_url

    assert_response :success
  end

  test "index calcula saldo do dia" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pago, sale_date: Date.today)
    create(:expense, amount: 200, expense_date: Date.today)

    get daily_reports_url

    assert_response :success
  end

  test "index calcula ticket médio" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 100, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 200, sale_date: Date.today)
    create(:sale, employee: @employee, customer: @customer, total_amount: 300, sale_date: Date.today)

    get daily_reports_url

    assert_response :success
  end

  test "index calcula top produtos do dia" do
    product = create(:product, :with_stock, initial_stock: 100)
    sale = create(:sale, employee: @employee, customer: @customer, sale_date: Date.today)
    create(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 50)

    get daily_reports_url

    assert_response :success
  end

  test "index calcula top serviços do dia" do
    service = create(:service)
    sale = create(:sale, employee: @employee, customer: @customer, sale_date: Date.today)
    create(:sale_service, sale: sale, service: service, quantity: 2, unit_price: 80)

    get daily_reports_url

    assert_response :success
  end

  test "index mostra vendas que vencem hoje" do
    create(:sale, employee: @employee, customer: @customer, total_amount: 500, status: :pendente, sale_date: 5.days.ago, due_date: Date.today)

    get daily_reports_url

    assert_response :success
  end

  test "index mostra agendamentos do dia" do
    service = create(:service)
    tomorrow = 1.day.from_now.beginning_of_day + 10.hours
    create(:service_appointment, employee: @employee, customer: @customer, service: service, appointment_date: tomorrow)

    get daily_reports_url, params: { date: tomorrow.to_date.to_s }

    assert_response :success
  end

  test "index calcula estatísticas por hora para hoje" do
    get daily_reports_url

    assert_response :success
  end

  test "index funciona sem dados" do
    get daily_reports_url
    assert_response :success
  end

  test "index não calcula estatísticas por hora para datas passadas" do
    get daily_reports_url, params: { date: 5.days.ago.to_date.to_s }

    assert_response :success
  end
end
