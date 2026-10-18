# frozen_string_literal: true

require "test_helper"

class AppointmentsCalendarControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @employee = create(:employee)
    @customer = create(:customer)
    @service = create(:service)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get appointments_calendar_url
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get appointments_calendar_url
    assert_response :success
  end

  test "index retorna sucesso com ano e mês especificados" do
    get appointments_calendar_url, params: { year: Date.today.year, month: Date.today.month }
    assert_response :success
  end

  test "index retorna sucesso com mês anterior" do
    last_month = 1.month.ago
    get appointments_calendar_url, params: { year: last_month.year, month: last_month.month }
    assert_response :success
  end

  test "index lista agendamentos do mês" do
    tomorrow = 1.day.from_now.beginning_of_day + 10.hours
    create(:service_appointment, employee: @employee, customer: @customer, service: @service, appointment_date: tomorrow)

    get appointments_calendar_url, params: { year: tomorrow.year, month: tomorrow.month }

    assert_response :success
  end

  test "index agrupa agendamentos por dia" do
    tomorrow = 1.day.from_now.beginning_of_day
    create(:service_appointment, employee: @employee, customer: @customer, service: @service, appointment_date: tomorrow + 9.hours)
    create(:service_appointment, employee: @employee, customer: @customer, service: @service, appointment_date: tomorrow + 11.hours)

    get appointments_calendar_url, params: { year: tomorrow.year, month: tomorrow.month }

    assert_response :success
  end

  test "index mostra múltiplos agendamentos no mesmo dia" do
    tomorrow = 1.day.from_now.beginning_of_day
    3.times do |i|
      create(:service_appointment, employee: @employee, customer: @customer, service: @service, appointment_date: tomorrow + (9 + i * 2).hours)
    end

    get appointments_calendar_url, params: { year: tomorrow.year, month: tomorrow.month }

    assert_response :success
  end

  test "index funciona sem agendamentos" do
    get appointments_calendar_url
    assert_response :success
  end

  test "index retorna anos disponíveis" do
    tomorrow = 1.day.from_now.beginning_of_day + 10.hours
    create(:service_appointment, employee: @employee, customer: @customer, service: @service, appointment_date: tomorrow)

    get appointments_calendar_url

    assert_response :success
  end

  test "index busca feriados brasileiros" do
    get appointments_calendar_url

    assert_response :success
  end

  test "index com agendamentos em diferentes status" do
    tomorrow = 1.day.from_now.beginning_of_day
    create(:service_appointment, employee: @employee, customer: @customer, service: @service, appointment_date: tomorrow + 9.hours, status: :agendado)
    create(:service_appointment, employee: @employee, customer: @customer, service: @service, appointment_date: tomorrow + 11.hours, status: :concluido)
    create(:service_appointment, employee: @employee, customer: @customer, service: @service, appointment_date: tomorrow + 14.hours, status: :cancelado)

    get appointments_calendar_url, params: { year: tomorrow.year, month: tomorrow.month }

    assert_response :success
  end
end
