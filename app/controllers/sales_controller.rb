class SalesController < ApplicationController
  before_action :set_sale, only: [:show, :edit, :update, :destroy, :mark_as_paid]

  def index
    @sales = Sale.includes(:customer, :employee)

    @sales = @sales.by_status(params[:status]) if params[:status].present?
    @sales = @sales.where(payment_method: params[:payment_method]) if params[:payment_method].present?
    @sales = @sales.by_customer(params[:customer_id]) if params[:customer_id].present?
    @sales = @sales.by_employee(params[:employee_id]) if params[:employee_id].present?

    if params[:start_date].present? && params[:end_date].present?
      @sales = @sales.by_period(params[:start_date], params[:end_date])
    end

    # Ordenação por valor total
    if params[:sort_amount].present?
      @sales = @sales.order(total_amount: params[:sort_amount] == 'desc' ? :desc : :asc)
    # Ordenação por valor descontado em reais (desconto em reais)
    elsif params[:sort_discounted_amount].present?
      # Ordenar por valor do desconto em reais (total_amount * discount_percentage / 100)
      order_direction = params[:sort_discounted_amount] == 'desc' ? 'DESC' : 'ASC'
      @sales = @sales.order(Arel.sql("total_amount * COALESCE(discount_percentage, 0)::float / 100 #{order_direction}"))
    # Ordenação por desconto aplicado (percentual)
    elsif params[:sort_discount].present?
      @sales = @sales.order(discount_percentage: params[:sort_discount] == 'desc' ? :desc : :asc)
    else
      # Ordenação padrão (mais recente)
      @sales = @sales.recent
    end

    # Aplicar paginação DEPOIS de todas as ordenações
    @sales = @sales.page(params[:page]).per(20)
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

    if params[:sale][:customer_id].blank? && params[:customer_search].present?
    customer_name = params[:customer_search].strip
    customer = Customer.create(full_name: customer_name)
    @sale.customer = customer
    end

    if @sale.save
      redirect_to @sale, notice: 'Venda criada com sucesso.'
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def update

    if params[:sale][:customer_id].blank? && params[:customer_search].present?
    customer_name = params[:customer_search].strip
    customer = Customer.create(full_name: customer_name)
    @sale.customer = customer
    end

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

  def search_employees
    query = params[:query].to_s.strip
    @employees = Employee.where(status: 'ativo')
                        .where("full_name ILIKE ?", "%#{query}%")
                        .order(:full_name)
                        .limit(10)

    render json: @employees.map { |e| { id: e.id, name: e.full_name } }
  end

  def search_customers
    query = params[:query].to_s.strip
    @customers = Customer.where("full_name ILIKE ?", "%#{query}%")
                        .order(:full_name)
                        .limit(10)

    render json: @customers.map { |c| { id: c.id, name: c.full_name } }
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

    # Mapeia as opções de status para português e mantém a ordem
    status_labels = {
      'pendente' => 'Pendente',
      'pago' => 'Pago',
      'cancelado' => 'Cancelado',
      'expirado' => 'Expirado'
    }
    @statuses = Sale.statuses.keys.map { |s| [status_labels[s], s] }
  end
end