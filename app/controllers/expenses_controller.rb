class ExpensesController < ApplicationController
  before_action :set_expense, only: [ :show, :edit, :update, :destroy, :cancel, :reactivate ]

  def index
    # PERFORMANCE: Eager loading de associações e ordenação otimizada
    @expenses = Expense.includes(:employee, :supplier).recent
    @expenses = @expenses.by_employee(params[:employee_id]) if params[:employee_id].present?
    @expenses = @expenses.by_supplier(params[:supplier_id]) if params[:supplier_id].present?
    @expenses = @expenses.by_expense_type(params[:expense_type]) if params[:expense_type].present?
    @expenses = @expenses.by_category(params[:category]) if params[:category].present?
    @expenses = @expenses.by_payment_method(params[:payment_method]) if params[:payment_method].present?
    start_date = parse_filter_date(params[:start_date])
    end_date = parse_filter_date(params[:end_date])
    @expenses = @expenses.by_date_range(start_date, end_date) if start_date && end_date
    @expenses = @expenses.where(status: params[:status]) if params[:status].present?

    load_expense_kpis(@expenses)

    @expenses = @expenses.page(params[:page]).per(per_page)
  end

  def show
  end

  def new
    @expense = Expense.new
  end

  def create
    @expense = Expense.new(expense_params)

    if @expense.save
      redirect_to @expense, notice: "Despesa registrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense.update(expense_params)
      redirect_to @expense, notice: "Despesa atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_url, notice: "Despesa removida com sucesso."
  end

 def cancel
  @expense.update(status: :inativa)  # Zera o valor + muda status
  redirect_to @expense, notice: "Despesa inativada com sucesso."
end

def reactivate
  @expense.update(status: :ativa)  # Reativa, mas mantém valor zerado
  redirect_to @expense, notice: "Despesa reativada com sucesso."
end


  private

  def set_expense
    # PERFORMANCE: Eager loading para show/edit
    @expense = Expense.includes(:employee, :supplier).find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:employee_id, :supplier_id, :expense_date, :expense_type, :amount, :payment_method, :notes, :category, :status)
  end

  # KPIs calculados sobre o escopo filtrado (antes da paginação), para refletir
  # os filtros aplicados sem ficar restrito aos itens da página atual
  def load_expense_kpis(scope)
    active_scope = params[:status].present? ? scope : scope.where(status: "ativa")

    @total_expenses_amount = active_scope.sum(:amount)
    @total_expenses_count = active_scope.count
    @average_expense_amount = active_scope.average(:amount)&.round(2) || 0
    @monthly_fixed_total = active_scope.monthly_fixed.sum(:amount)

    current_month = Date.current.beginning_of_month..Date.current.end_of_month
    previous_month_date = 1.month.ago.to_date
    previous_month = previous_month_date.beginning_of_month..previous_month_date.end_of_month

    @current_month_total = active_scope.where(expense_date: current_month).sum(:amount)
    previous_month_total = active_scope.where(expense_date: previous_month).sum(:amount)

    @month_over_month_change = if previous_month_total.positive?
      (((@current_month_total - previous_month_total) / previous_month_total) * 100).round(1)
    end
  end
end
