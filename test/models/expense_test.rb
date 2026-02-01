# frozen_string_literal: true

require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  setup do
    @employee = create(:employee)
    @supplier = create(:supplier)
    @expense = create(:expense, employee: @employee, supplier: @supplier)
  end

  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar despesa com atributos válidos" do
    expense = build(:expense, employee: @employee, supplier: @supplier)
    assert_valid expense
  end

  test "deve exigir funcionário" do
    expense = build(:expense, employee: nil, supplier: @supplier)
    assert_invalid expense, :employee_id
  end

  test "supplier é opcional" do
    expense = build(:expense, employee: @employee, supplier: nil)
    assert_valid expense
  end

  test "deve exigir data da despesa" do
    expense = build(:expense, employee: @employee, supplier: @supplier, expense_date: nil)
    assert_invalid expense, :expense_date
  end

  test "deve exigir valor" do
    expense = build(:expense, employee: @employee, supplier: @supplier, amount: nil)
    assert_invalid expense, :amount
  end

  test "valor deve ser maior que zero" do
    expense = build(:expense, employee: @employee, supplier: @supplier, amount: 0)
    assert_invalid expense, :amount
  end

  test "valor não pode ser negativo" do
    expense = build(:expense, employee: @employee, supplier: @supplier, amount: -100)
    assert_invalid expense, :amount
  end

  test "deve exigir tipo de despesa" do
    expense = build(:expense, employee: @employee, supplier: @supplier, expense_type: nil)
    assert_invalid expense, :expense_type
  end

  test "deve exigir método de pagamento" do
    expense = build(:expense, employee: @employee, supplier: @supplier, payment_method: nil)
    assert_invalid expense, :payment_method
  end

  test "deve exigir categoria" do
    expense = build(:expense, employee: @employee, supplier: @supplier, category: nil)
    assert_invalid expense, :category
  end

  test "deve exigir status" do
    expense = build(:expense, employee: @employee, supplier: @supplier, status: nil)
    assert_invalid expense, :status
  end

  # ============================================
  # ASSOCIAÇÕES
  # ============================================

  test "pertence a funcionário" do
    assert_equal @employee, @expense.employee
  end

  test "pertence a fornecedor" do
    assert_equal @supplier, @expense.supplier
  end

  # ============================================
  # ENUMS
  # ============================================

  test "expense_type enum tem valores esperados" do
    expected = %w[aluguel utilities salaries supplies maintenance marketing insurance taxes other]
    assert_equal expected, Expense.expense_types.keys
  end

  test "payment_method enum tem valores esperados" do
    expected = %w[dinheiro cartao_credito cartao_debito pix transferencia boleto]
    assert_equal expected, Expense.payment_methods.keys
  end

  test "category enum tem valores esperados" do
    expected = %w[fixa_mensal fixa_anual esporadica rara]
    assert_equal expected, Expense.categories.keys
  end

  test "status enum tem valores esperados" do
    expected = %w[ativa inativa]
    assert_equal expected, Expense.statuses.keys
  end

  # ============================================
  # LABELS
  # ============================================

  test "expense_type_label retorna label legível" do
    expense = build(:expense, expense_type: "aluguel")
    assert_equal "Aluguel", expense.expense_type_label
  end

  test "category_label retorna label legível" do
    expense = build(:expense, category: "fixa_mensal")
    assert_equal "Fixa Mensal", expense.category_label
  end

  test "status_label retorna label legível" do
    expense = build(:expense, status: "ativa")
    assert_equal "Ativa", expense.status_label
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope by_employee filtra por funcionário" do
    other_employee = create(:employee)
    other_expense = create(:expense, employee: other_employee, supplier: @supplier)

    result = Expense.by_employee(@employee.id)

    assert_includes result, @expense
    assert_not_includes result, other_expense
  end

  test "scope by_supplier filtra por fornecedor" do
    other_supplier = create(:supplier)
    other_expense = create(:expense, employee: @employee, supplier: other_supplier)

    result = Expense.by_supplier(@supplier.id)

    assert_includes result, @expense
    assert_not_includes result, other_expense
  end

  test "scope by_category filtra por categoria" do
    fixa = create(:expense, employee: @employee, supplier: @supplier, category: :fixa_mensal)
    esporadica = create(:expense, employee: @employee, supplier: @supplier, category: :esporadica)

    result = Expense.by_category(:fixa_mensal)

    assert_includes result, fixa
    assert_not_includes result, esporadica
  end

  test "scope by_date_range filtra por período" do
    inside = create(:expense, employee: @employee, supplier: @supplier, expense_date: 5.days.ago)
    outside = create(:expense, employee: @employee, supplier: @supplier, expense_date: 15.days.ago)

    result = Expense.by_date_range(10.days.ago, Date.current)

    assert_includes result, inside
    assert_not_includes result, outside
  end

  test "scope active filtra despesas ativas" do
    ativa = create(:expense, employee: @employee, supplier: @supplier, status: :ativa)
    inativa = create(:expense, employee: @employee, supplier: @supplier, status: :inativa)

    result = Expense.active

    assert_includes result, ativa
    assert_not_includes result, inativa
  end

  test "scope inactive filtra despesas inativas" do
    ativa = create(:expense, employee: @employee, supplier: @supplier, status: :ativa)
    inativa = create(:expense, employee: @employee, supplier: @supplier, status: :inativa)

    result = Expense.inactive

    assert_includes result, inativa
    assert_not_includes result, ativa
  end

  test "scope recent ordena por data decrescente" do
    old_expense = create(:expense, employee: @employee, supplier: @supplier, expense_date: 10.days.ago)
    new_expense = create(:expense, employee: @employee, supplier: @supplier, expense_date: Date.current)

    result = Expense.recent

    assert_equal new_expense, result.first
  end
end
