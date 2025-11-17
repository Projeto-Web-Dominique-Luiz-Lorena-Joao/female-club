class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = Customer.all.order(created_at: :desc)

    if params[:search].present?
      search_term = params[:search].strip
      clean_search = search_term.gsub(/\D/, '')

      conditions = ['full_name ILIKE ? OR email ILIKE ?']
      values = ["%#{search_term}%", "%#{search_term}%"]

      if clean_search.present?
        conditions << "REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g') LIKE ?"
        values << "%#{clean_search}%"

        conditions << "REGEXP_REPLACE(cpf, '[^0-9]', '', 'g') LIKE ?"
        values << "%#{clean_search}%"
      end

      @customers = @customers.where(conditions.join(' OR '), *values)
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
      # Processar fiador se os dados foram fornecidos
      if params[:guarantor].present? && params[:guarantor][:full_name].present?
        create_or_update_guarantor(@customer)
      end

      redirect_to customers_path, notice: 'Cliente cadastrado com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @customer.update(customer_params)
      # Processar fiador se os dados foram fornecidos
      if params[:guarantor].present? && params[:guarantor][:full_name].present?
        create_or_update_guarantor(@customer)
      end

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

  def create_or_update_guarantor(customer)
    guarantor_params = params[:guarantor]

    if guarantor_params[:id].present?
      # Atualizar fiador existente
      guarantor = Guarantor.find(guarantor_params[:id])
      guarantor.update(
        full_name: guarantor_params[:full_name],
        cpf: guarantor_params[:cpf],
        phone: guarantor_params[:phone],
        relationship: guarantor_params[:relationship],
        address: guarantor_params[:address]
      )
      customer.update(guarantor: guarantor)
    else
      # Criar novo fiador
      guarantor = Guarantor.create(
        full_name: guarantor_params[:full_name],
        cpf: guarantor_params[:cpf],
        phone: guarantor_params[:phone],
        relationship: guarantor_params[:relationship],
        address: guarantor_params[:address]
      )
      customer.update(guarantor: guarantor)
    end
  end
end