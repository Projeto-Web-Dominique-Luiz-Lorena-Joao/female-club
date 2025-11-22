require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @employee = Employee.find_or_create_by!(full_name: "Test Employee", cpf: "77777777777", position: "gerente", phone: "11988888888", salary: 3000)
    @supplier = Supplier.find_or_create_by!(legal_name: "Test Supplier", status: "ativo")
    @expense = Expense.create!(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 1500.00,
      payment_method: "transferencia",
      category: "fixa_mensal",
      notes: "Test expense"
    )
  end

  test "should get index" do
    get expenses_url
    assert_response :success
  end

  test "should get new" do
    get new_expense_url
    assert_response :success
  end

  test "should create expense" do
    assert_difference("Expense.count") do
      post expenses_url, params: {
        expense: {
          employee_id: @employee.id,
          supplier_id: @supplier.id,
          expense_date: Date.today,
          expense_type: "utilities",
          amount: 500.00,
          payment_method: "pix",
          category: "esporadica",
          notes: "Test"
        }
      }
    end

    assert_redirected_to expense_url(Expense.last)
  end

  test "should get show" do
    get expense_url(@expense)
    assert_response :success
  end

  test "should get edit" do
    get edit_expense_url(@expense)
    assert_response :success
  end

  test "should update expense" do
    patch expense_url(@expense), params: {
      expense: {
        amount: 2000.00,
        notes: "Updated test expense"
      }
    }

    assert_redirected_to expense_url(@expense)
    @expense.reload
    assert_equal 2000.00, @expense.amount
  end

  test "should destroy expense" do
    assert_difference("Expense.count", -1) do
      delete expense_url(@expense)
    end

    assert_redirected_to expenses_url
  end
end
