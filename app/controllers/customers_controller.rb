class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = Customer.all.order(created_at: :desc)
    
    if params[:search].present?
      @customers = @customers.where(
        'full_name ILIKE ? OR cpf ILIKE ? OR phone_number ILIKE ?', 
        "%#{params[:search]}%", 
        "%#{params[:search]}%",
        "%#{params[:search]}%"
      )
    end
    
    case params[:tier]
    when 'vip'
      @customers = @customers.vip
    when 'active'
      @customers = @customers.active
    end
    

    @total_customers = @customers.count
    # @active_customers = Customer.active.count
    # @vip_customers = Customer.vip.count
   # @total_revenue = Customer.joins(:sales).sum('sales.total_amount')
  end

  def show
    # @recent_purchases = @customer.sales.recent.limit(10)
    # @upcoming_appointments = @customer.service_appointments.upcoming.limit(5)
  end

  def new
    @customer = Customer.new
  end

  def edit
  end

  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      redirect_to customers_path, notice: 'Cliente cadastrado com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @customer.update(customer_params)
      redirect_to customers_path, notice: 'Cliente atualizado com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    # redirect_to customers_path, notice: 'Cliente excluído com sucesso!'
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(
      :full_name, :cpf, :birth_date, :phone_number, 
      :email, :full_address, :notes
    )
  end
end