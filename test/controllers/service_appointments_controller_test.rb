# frozen_string_literal: true

require "test_helper"

class ServiceAppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @employee = create(:employee)
    @customer = create(:customer)
    @service = create(:service)
    @appointment = create(:service_appointment,
                          employee: @employee,
                          customer: @customer,
                          service: @service)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get service_appointments_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get service_appointment_url(@appointment)
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para new" do
    sign_out @user
    get new_service_appointment_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para create" do
    sign_out @user
    post service_appointments_url, params: { service_appointment: {} }
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get service_appointments_url
    assert_response :success
  end

  test "index lista agendamentos" do
    get service_appointments_url
    assert_select "table" # Verifica que há uma tabela
  end

  test "index filtra por data" do
    tomorrow = 1.day.from_now.to_date
    get service_appointments_url, params: { date: tomorrow }
    assert_response :success
  end

  test "index filtra por status" do
    get service_appointments_url, params: { status: "agendado" }
    assert_response :success
  end

  test "index busca por termo" do
    get service_appointments_url, params: { search: @customer.full_name }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get service_appointment_url(@appointment)
    assert_response :success
  end

  test "show exibe detalhes do agendamento" do
    get service_appointment_url(@appointment)
    assert_select "h1", /Detalhes do Agendamento|Agendamento/i
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_service_appointment_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_service_appointment_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria novo agendamento com dados válidos" do
    appointment_date = 2.days.from_now.change(hour: 14, min: 0)

    assert_difference "ServiceAppointment.count", 1 do
      post service_appointments_url, params: {
        service_appointment: {
          service_id: @service.id,
          employee_id: @employee.id,
          customer_id: @customer.id,
          appointment_date: appointment_date,
          duration_minutes: 60,
          status: "agendado"
        }
      }
    end

    assert_redirected_to service_appointment_url(ServiceAppointment.last)
  end

  test "create não cria agendamento com dados inválidos" do
    assert_no_difference "ServiceAppointment.count" do
      post service_appointments_url, params: {
        service_appointment: {
          service_id: nil,
          employee_id: nil,
          customer_id: nil,
          appointment_date: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create não permite agendamento com conflito" do
    # Criar agendamento existente
    existing_date = 3.days.from_now.change(hour: 10, min: 0)
    create(:service_appointment,
           employee: @employee,
           appointment_date: existing_date,
           duration_minutes: 60)

    # Tentar criar outro no mesmo horário
    assert_no_difference "ServiceAppointment.count" do
      post service_appointments_url, params: {
        service_appointment: {
          service_id: @service.id,
          employee_id: @employee.id,
          customer_id: @customer.id,
          appointment_date: existing_date,
          duration_minutes: 60,
          status: "agendado"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_service_appointment_url(@appointment)
    assert_response :success
  end

  test "edit exibe formulário preenchido" do
    get edit_service_appointment_url(@appointment)
    assert_select "form"
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza agendamento com dados válidos" do
    new_date = 5.days.from_now.change(hour: 15, min: 0)

    patch service_appointment_url(@appointment), params: {
      service_appointment: {
        appointment_date: new_date
      }
    }

    assert_redirected_to service_appointment_url(@appointment)
    @appointment.reload
    assert_equal new_date.to_i, @appointment.appointment_date.to_i
  end

  test "update pode alterar status para concluído" do
    patch service_appointment_url(@appointment), params: {
      service_appointment: {
        status: "concluido"
      }
    }

    assert_redirected_to service_appointment_url(@appointment)
    @appointment.reload
    assert @appointment.concluido?
  end

  test "update pode alterar duração" do
    patch service_appointment_url(@appointment), params: {
      service_appointment: {
        duration_minutes: 90
      }
    }

    assert_redirected_to service_appointment_url(@appointment)
    @appointment.reload
    assert_equal 90, @appointment.duration_minutes
  end

  test "update não permite mover para horário com conflito" do
    # Criar outro agendamento
    other_date = 4.days.from_now.change(hour: 10, min: 0)
    create(:service_appointment,
           employee: @appointment.employee,
           appointment_date: other_date,
           duration_minutes: 60)

    # Tentar mover o agendamento atual para o mesmo horário
    patch service_appointment_url(@appointment), params: {
      service_appointment: {
        appointment_date: other_date
      }
    }

    assert_response :unprocessable_entity
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy remove agendamento" do
    assert_difference "ServiceAppointment.count", -1 do
      delete service_appointment_url(@appointment)
    end

    assert_redirected_to service_appointments_url
  end

  # ============================================
  # CHECK_CONFLICTS (AJAX)
  # ============================================

  test "check_conflicts retorna disponível para slot livre" do
    free_time = 10.days.from_now.change(hour: 10, min: 0)

    get check_conflicts_service_appointments_url, params: {
      employee_id: @employee.id,
      start_time: free_time.iso8601,
      duration_minutes: 60
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["available"]
  end

  test "check_conflicts retorna indisponível para slot ocupado" do
    # Criar agendamento
    occupied_time = 11.days.from_now.change(hour: 10, min: 0)
    create(:service_appointment,
           employee: @employee,
           appointment_date: occupied_time,
           duration_minutes: 60)

    get check_conflicts_service_appointments_url, params: {
      employee_id: @employee.id,
      start_time: occupied_time.iso8601,
      duration_minutes: 60
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_not json["available"]
  end

  test "check_conflicts exclui agendamento sendo editado" do
    get check_conflicts_service_appointments_url, params: {
      employee_id: @appointment.employee_id,
      start_time: @appointment.appointment_date.iso8601,
      duration_minutes: @appointment.duration_minutes,
      exclude_id: @appointment.id
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["available"]
  end

  # ============================================
  # SEARCH ENDPOINTS
  # ============================================

  test "search_services retorna serviços" do
    get search_services_service_appointments_url, params: { q: @service.name }, as: :json
    assert_response :success
  end

  test "search_employees retorna funcionários" do
    get search_employees_service_appointments_url, params: { q: @employee.full_name }, as: :json
    assert_response :success
  end

  test "search_customers retorna clientes" do
    get search_customers_service_appointments_url, params: { q: @customer.full_name }, as: :json
    assert_response :success
  end
end
