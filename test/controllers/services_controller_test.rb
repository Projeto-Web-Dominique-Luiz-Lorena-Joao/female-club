# frozen_string_literal: true

require "test_helper"

class ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @service = create(:service)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get services_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get service_url(@service)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get services_url
    assert_response :success
  end

  test "index lista serviços" do
    get services_url
    assert_select "table"
  end

  test "index busca por termo" do
    get services_url, params: { search: @service.name }
    assert_response :success
  end

  test "index filtra por status" do
    get services_url, params: { status: "ativo" }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get service_url(@service)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_service_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_service_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria serviço com dados válidos" do
    assert_difference "Service.count", 1 do
      post services_url, params: {
        service: {
          name: "Novo Serviço",
          description: "Descrição do serviço",
          price: 150.00,
          duration_minutes: 60,
          active: "ativo"
        }
      }
    end

    assert_redirected_to service_url(Service.last)
  end

  test "create não cria serviço sem nome" do
    assert_no_difference "Service.count" do
      post services_url, params: {
        service: {
          name: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_service_url(@service)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza serviço" do
    patch service_url(@service), params: {
      service: {
        name: "Nome Atualizado"
      }
    }

    assert_redirected_to service_url(@service)
    @service.reload
    assert_equal "Nome Atualizado", @service.name
  end

  test "update pode alterar preço" do
    patch service_url(@service), params: {
      service: {
        price: 250.00
      }
    }

    assert_redirected_to service_url(@service)
    @service.reload
    assert_equal 250.00, @service.price.to_f
  end

  test "update pode inativar serviço" do
    patch service_url(@service), params: {
      service: {
        active: "inativo"
      }
    }

    assert_redirected_to service_url(@service)
    @service.reload
    assert @service.inativo?
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy remove serviço" do
    service_to_delete = create(:service)

    assert_difference "Service.count", -1 do
      delete service_url(service_to_delete)
    end

    assert_redirected_to services_url
  end

  test "destroy com erro retorna alerta" do
    service_to_delete = create(:service)

    # Simular falha na exclusão
    Service.any_instance.stubs(:destroy).returns(false)

    assert_no_difference "Service.count" do
      delete service_url(service_to_delete)
    end

    assert_redirected_to services_url
    assert_equal "Erro ao excluir serviço. Verifique se não há registros relacionados.", flash[:alert]
  end

  # ============================================
  # FILTROS
  # ============================================

  test "index filtra por active ativo" do
    active_service = create(:service, active: "ativo")
    inactive_service = create(:service, active: "inativo")

    get services_url, params: { active: "ativo" }
    assert_response :success
  end

  test "index filtra por active inativo" do
    active_service = create(:service, active: "ativo")
    inactive_service = create(:service, active: "inativo")

    get services_url, params: { active: "inativo" }
    assert_response :success
  end

  # ============================================
  # SHOW COM RELACIONAMENTOS
  # ============================================

  test "show exibe sale_services do serviço" do
    employee = create(:employee)
    sale = create(:sale, employee: employee)
    sale_service = create(:sale_service, sale: sale, service: @service)

    get service_url(@service)
    assert_response :success
  end

  test "show exibe service_appointments do serviço" do
    employee = create(:employee)
    customer = create(:customer)
    appointment = create(:service_appointment,
                         service: @service,
                         employee: employee,
                         customer: customer)

    get service_url(@service)
    assert_response :success
  end

  # ============================================
  # UPDATE COM ERRO
  # ============================================

  test "update com dados inválidos retorna erro" do
    patch service_url(@service), params: {
      service: {
        name: ""  # Nome vazio é inválido
      }
    }

    assert_response :unprocessable_entity
  end

end
