require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  def setup
    @employee = Employee.find_or_create_by!(full_name: "Test Employee", cpf: "66666666666", position: "gerente", phone: "11988888888", salary: 3000)
    @supplier = Supplier.find_or_create_by!(legal_name: "Test Supplier", status: "ativo")
  end

  test "should create expense with valid attributes" do
    expense = Expense.create!(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 1500.00,
      payment_method: "transferencia",
      category: "fixa_mensal",
      notes: "Monthly rent"
    )

    assert expense.persisted?
    assert_equal "aluguel", expense.expense_type
    assert_equal "fixa_mensal", expense.category
  end

  test "should validate presence of employee" do
    expense = Expense.new(
      employee: nil,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 1500.00,
      payment_method: "transferencia",
      category: "fixa_mensal"
    )

    assert_not expense.valid?
    assert expense.errors[:employee_id].present?
  end

  test "should validate presence of supplier" do
    expense = Expense.new(
      employee: @employee,
      supplier: nil,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 1500.00,
      payment_method: "transferencia",
      category: "fixa_mensal"
    )

    assert_not expense.valid?
    assert expense.errors[:supplier_id].present?
  end

  test "should validate presence of amount" do
    expense = Expense.new(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: nil,
      payment_method: "transferencia",
      category: "fixa_mensal"
    )

    assert_not expense.valid?
    assert expense.errors[:amount].present?
  end

  test "should validate amount is greater than zero" do
    expense = Expense.new(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 0,
      payment_method: "transferencia",
      category: "fixa_mensal"
    )

    assert_not expense.valid?
  end

  test "should validate expense_type presence" do
    expense = Expense.new(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: nil,
      amount: 1500.00,
      payment_method: "transferencia",
      category: "fixa_mensal"
    )

    assert_not expense.valid?
    assert expense.errors[:expense_type].present?
  end

  test "should validate payment_method presence" do
    expense = Expense.new(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 1500.00,
      payment_method: nil,
      category: "fixa_mensal"
    )

    assert_not expense.valid?
    assert expense.errors[:payment_method].present?
  end

  test "should validate category presence" do
    expense = Expense.new(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 1500.00,
      payment_method: "transferencia",
      category: nil
    )

    assert_not expense.valid?
    assert expense.errors[:category].present?
  end

  test "should have expense_type_label" do
    expense = Expense.create!(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 1500.00,
      payment_method: "transferencia",
      category: "fixa_mensal"
    )

    assert_equal "Aluguel", expense.expense_type_label
  end

  test "should have category_label" do
    expense = Expense.create!(
      employee: @employee,
      supplier: @supplier,
      expense_date: Date.today,
      expense_type: "aluguel",
      amount: 1500.00,
      payment_method: "transferencia",
      category: "fixa_mensal"
    )

    assert_equal "Fixa Mensal", expense.category_label
  end
end
