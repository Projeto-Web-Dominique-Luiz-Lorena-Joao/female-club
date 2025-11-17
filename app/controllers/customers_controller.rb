class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  def index
    @customers = Customer.all.order(created_at: :desc)

    if params[:search].present?
      search_term = params[:search].strip
      clean_search = search_term.gsub(/\D/, "")

      conditions = [ "full_name ILIKE ? OR email ILIKE ?" ]
      values = [ "%#{search_term}%", "%#{search_term}%" ]

      if clean_search.present?
        conditions << "REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g') LIKE ?"
        values << "%#{clean_search}%"

        conditions << "REGEXP_REPLACE(cpf, '[^0-9]', '', 'g') LIKE ?"
        values << "%#{clean_search}%"
      end

      @customers = @customers.where(conditions.join(" OR "), *values)
    end

    case params[:tier]
    when "vip"
      @customers = @customers.vip
    when "active"
      @customers = @customers.active
    end

    @total_customers = @customers.count
  end

  def show
  end

  def new
    @customer = Customer.new
  end

  def edit
  end

  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      redirect_to customers_path, notice: "Cliente cadastrado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @customer.update(customer_params)
      redirect_to customers_path, notice: "Cliente atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_path, notice: "Cliente excluído com sucesso!"
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
