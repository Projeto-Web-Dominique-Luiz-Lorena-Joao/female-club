class SalesController < ApplicationController
  before_action :set_sale, only: [:show, :edit, :update, :destroy, :mark_as_paid]

  def index
    @sales = Sale.includes(:customer, :employee)
                 .recent
                 .page(params[:page])
                 .per(20)

    @sales = @sales.by_status(params[:status]) if params[:status].present?
    @sales = @sales.by_customer(params[:customer_id]) if params[:customer_id].present?
    @sales = @sales.by_employee(params[:employee_id]) if params[:employee_id].present?

    if params[:start_date].present? && params[:end_date].present?
      @sales = @sales.by_period(params[:start_date], params[:end_date])
    end
  end

  def show
  end

  def new
    @sale = Sale.new(sale_date: Date.today)
    load_form_data
  end

  def edit
    load_form_data
  end

  def create
    @sale = Sale.new(sale_params)

    if @sale.save
      redirect_to @sale, notice: 'Venda criada com sucesso.'
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @sale.update(sale_params)
      redirect_to @sale, notice: 'Venda atualizada com sucesso.'
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sale.destroy
    redirect_to sales_url, notice: 'Venda excluída com sucesso.'
  end

  def mark_as_paid
    if @sale.mark_as_paid!
      redirect_to @sale, notice: 'Venda marcada como paga.'
    else
      redirect_to @sale, alert: 'Erro ao marcar venda como paga.'
    end
  end

  private

  def set_sale
    @sale = Sale.find(params[:id])
  end

  def sale_params
    params.require(:sale).permit(
      :customer_id,
      :employee_id,
      :sale_date,
      :due_date,
      :discount_percentage,
      :total_amount,
      :payment_method,
      :notes,
      :status,
      :paid_date
    )
  end


  def load_form_data
    @customers = Customer.order(:full_name)
    @employees = Employee.where(status: 'active').order(:full_name)
    @payment_methods = [
      ['Dinheiro', 'dinheiro'],
      ['Cartão de Crédito', 'cartao_credito'],
      ['Cartão de Débito', 'cartao_debito'],
      ['PIX', 'pix'],
      ['Transferência', 'transferencia'],
      ['Boleto', 'boleto']
    ]


    @statuses = Sale.statuses.keys.map { |s| [s.capitalize, s] }
  end
end