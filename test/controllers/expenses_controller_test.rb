# frozen_string_literal: true

require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @employee = create(:employee)
    @supplier = create(:supplier)
    @expense = create(:expense, employee: @employee, supplier: @supplier)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get expenses_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get expense_url(@expense)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get expenses_url
    assert_response :success
  end

  test "index lista despesas" do
    get expenses_url
    assert_select "table"
  end

  test "index calcula KPIs sobre o total filtrado, nao apenas a pagina atual" do
    @expense.update!(status: :inativa) # remove a despesa padrão do setup do cálculo
    20.times { create(:expense, amount: 100, status: :ativa, expense_date: Date.current) }

    get expenses_url
    assert_response :success
    assert_match "2.000,00", response.body
  end

  test "index calcula despesas fixas mensais somando apenas categoria fixa_mensal" do
    @expense.update!(status: :inativa)
    create(:expense, :aluguel, status: :ativa)
    create(:expense, category: :esporadica, amount: 999, status: :ativa)

    get expenses_url
    assert_response :success
    assert_match "2.500,00", response.body
  end

  test "index calcula total do mes atual excluindo meses anteriores" do
    @expense.update!(status: :inativa)
    create(:expense, amount: 300, status: :ativa, expense_date: Date.current)
    create(:expense, amount: 500, status: :ativa, expense_date: 2.months.ago)

    get expenses_url
    assert_response :success
    assert_match "300,00", response.body
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get expense_url(@expense)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_expense_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_expense_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria despesa com dados válidos" do
    assert_difference "Expense.count", 1 do
      post expenses_url, params: {
        expense: {
          employee_id: @employee.id,
          supplier_id: @supplier.id,
          expense_date: Date.current,
          expense_type: "utilities",
          amount: 500.00,
          payment_method: "pix",
          category: "esporadica",
          notes: "Conta de luz"
        }
      }
    end

    assert_redirected_to expense_url(Expense.last)
  end

  test "create não cria despesa sem funcionário" do
    assert_no_difference "Expense.count" do
      post expenses_url, params: {
        expense: {
          employee_id: nil,
          expense_date: Date.current,
          expense_type: "utilities",
          amount: 500.00,
          payment_method: "pix",
          category: "esporadica"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_expense_url(@expense)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza despesa" do
    new_amount = 2000.00

    patch expense_url(@expense), params: {
      expense: {
        amount: new_amount
      }
    }

    assert_redirected_to expense_url(@expense)
    @expense.reload
    assert_equal new_amount, @expense.amount
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy remove despesa" do
    expense_to_delete = create(:expense, employee: @employee, supplier: @supplier)

    assert_difference "Expense.count", -1 do
      delete expense_url(expense_to_delete)
    end

    assert_redirected_to expenses_url
  end

  # ============================================
  # FILTROS
  # ============================================

  test "index filtra por funcionário" do
    get expenses_url, params: { employee_id: @employee.id }
    assert_response :success
  end

  test "index filtra por fornecedor" do
    get expenses_url, params: { supplier_id: @supplier.id }
    assert_response :success
  end

  test "index filtra por tipo de despesa" do
    get expenses_url, params: { expense_type: @expense.expense_type }
    assert_response :success
  end

  test "index filtra por categoria" do
    get expenses_url, params: { category: @expense.category }
    assert_response :success
  end

  test "index filtra por método de pagamento" do
    get expenses_url, params: { payment_method: @expense.payment_method }
    assert_response :success
  end

  test "index filtra por período" do
    get expenses_url, params: {
      start_date: 1.month.ago.to_date,
      end_date: Date.current
    }
    assert_response :success
  end

  test "index filtra por status" do
    get expenses_url, params: { status: @expense.status }
    assert_response :success
  end

  # ============================================
  # INATIVAR E REATIVAR
  # ============================================

  test "cancel inativa despesa" do
    patch cancel_expense_url(@expense)

    assert_redirected_to expense_url(@expense)
    @expense.reload
    assert @expense.inativa?
  end

  test "reactivate reativa despesa" do
    inactive_expense = create(:expense, employee: @employee, supplier: @supplier, status: :inativa)

    patch reactivate_expense_url(inactive_expense)

    assert_redirected_to expense_url(inactive_expense)
    inactive_expense.reload
    assert inactive_expense.ativa?
  end

  # ============================================
  # UPDATE COM ERRO
  # ============================================

  test "update com dados inválidos retorna erro" do
    patch expense_url(@expense), params: {
      expense: {
        amount: -100  # Valor negativo é inválido
      }
    }

    assert_response :unprocessable_entity
  end
end
