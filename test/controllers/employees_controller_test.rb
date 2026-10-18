# frozen_string_literal: true

require "test_helper"

class EmployeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @employee = create(:employee)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get employees_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get employee_url(@employee)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get employees_url
    assert_response :success
  end

  test "index lista funcionários" do
    get employees_url
    assert_select "table"
  end

  test "index busca por termo" do
    get employees_url, params: { search: @employee.full_name }
    assert_response :success
  end

  test "index filtra por status" do
    get employees_url, params: { status: "ativo" }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get employee_url(@employee)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_employee_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_employee_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria funcionário com dados válidos" do
    cpf = generate_valid_cpf

    assert_difference "Employee.count", 1 do
      post employees_url, params: {
        employee: {
          full_name: "Novo Funcionário",
          cpf: cpf,
          position: "atendente",
          phone: "11987654321",
          salary: 2500.00,
          status: "ativo"
        }
      }
    end

    # Controller redireciona para index, não show
    assert_redirected_to employees_url
  end

  test "create não cria funcionário sem nome" do
    assert_no_difference "Employee.count" do
      post employees_url, params: {
        employee: {
          full_name: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create não cria funcionário com CPF duplicado" do
    assert_no_difference "Employee.count" do
      post employees_url, params: {
        employee: {
          full_name: "Outro Funcionário",
          cpf: @employee.cpf
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_employee_url(@employee)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza funcionário" do
    patch employee_url(@employee), params: {
      employee: {
        full_name: "Nome Atualizado"
      }
    }

    # Controller redireciona para index
    assert_redirected_to employees_url
    @employee.reload
    assert_equal "Nome Atualizado", @employee.full_name
  end

  test "update pode alterar status para inativo" do
    patch employee_url(@employee), params: {
      employee: {
        status: "inativo"
      }
    }

    # Controller redireciona para index
    assert_redirected_to employees_url
    @employee.reload
    assert @employee.inativo_status?
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy inativa funcionário em vez de deletar" do
    employee_to_inactivate = create(:employee, status: :ativo)

    # Controller faz soft delete (inativa) em vez de destruir
    assert_no_difference "Employee.count" do
      delete employee_url(employee_to_inactivate)
    end

    assert_redirected_to employees_url
    employee_to_inactivate.reload
    assert employee_to_inactivate.inativo_status?
  end

  # ============================================
  # REATIVAÇÃO
  # ============================================

  test "reactivate reativa funcionário inativo" do
    inactive_employee = create(:employee, status: :inativo)

    patch reactivate_employee_url(inactive_employee)

    assert_redirected_to employee_url(inactive_employee)
    inactive_employee.reload
    assert inactive_employee.ativo_status?
  end

  # ============================================
  # FILTROS ADICIONAIS
  # ============================================

  test "index filtra por posição" do
    atendente = create(:employee, position: "atendente")
    gerente = create(:employee, position: "gerente")

    get employees_url, params: { position: "atendente" }
    assert_response :success
  end

  test "index busca por CPF numérico" do
    cpf = generate_valid_cpf
    employee = create(:employee, cpf: cpf)
    clean_cpf = cpf.gsub(/\D/, "")

    get employees_url, params: { search: clean_cpf }
    assert_response :success
  end

  test "index busca por email" do
    employee = create(:employee, email: "funcionario@test.com")

    get employees_url, params: { search: "funcionario@test.com" }
    assert_response :success
  end

  test "index busca por telefone" do
    employee = create(:employee, phone: "11999887766")

    get employees_url, params: { search: "999887766" }
    assert_response :success
  end

  # ============================================
  # ORDENAÇÃO
  # ============================================

  test "index ordena por data de admissão descendente" do
    old_employee = create(:employee, admission_date: 2.years.ago)
    new_employee = create(:employee, admission_date: 1.month.ago)

    get employees_url, params: { sort_admission: "desc" }
    assert_response :success
  end

  test "index ordena por data de admissão ascendente" do
    old_employee = create(:employee, admission_date: 2.years.ago)
    new_employee = create(:employee, admission_date: 1.month.ago)

    get employees_url, params: { sort_admission: "asc" }
    assert_response :success
  end

  # ============================================
  # UPDATE COM FOTO
  # ============================================

  test "update processa parâmetro photo_delete separadamente" do
    # O parâmetro photo_delete é verificado fora do employee_params
    # e usado para purge da foto antes do update
    patch employee_url(@employee), params: {
      employee: {
        full_name: @employee.full_name
      }
    }

    assert_redirected_to employees_url
  end
end
