class ExpensesController < ApplicationController
  before_action :set_expense, only: [:show, :edit, :update, :destroy]

  def index
    @expenses = Expense.recent
    @expenses = @expenses.by_employee(params[:employee_id]) if params[:employee_id].present?
    @expenses = @expenses.by_supplier(params[:supplier_id]) if params[:supplier_id].present?
    @expenses = @expenses.by_expense_type(params[:expense_type]) if params[:expense_type].present?
    @expenses = @expenses.by_category(params[:category]) if params[:category].present?
    @expenses = @expenses.by_payment_method(params[:payment_method]) if params[:payment_method].present?
    @expenses = @expenses.by_date_range(params[:start_date].to_date, params[:end_date].to_date) if params[:start_date].present? && params[:end_date].present?
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

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:employee_id, :supplier_id, :expense_date, :expense_type, :amount, :payment_method, :notes, :category)
  end
end
