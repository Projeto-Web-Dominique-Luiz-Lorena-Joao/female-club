class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  def index
    # Otimizado: Calcular gasto total com SQL agregado para evitar N+1 queries
    @customers = Customer.left_joins(:sales)
                         .select("customers.*, COALESCE(SUM(CASE WHEN sales.status <> 'cancelado' THEN sales.total_amount ELSE 0 END), 0) as total_spent")
                         .group("customers.id")
                         .order("customers.created_at DESC")

    if params[:search].present?
      search_term  = sanitize_search(params[:search])
      clean_search = search_term.gsub(/\D/, "")

      conditions = [ "full_name ILIKE ? OR email ILIKE ?" ]
      values     = [ "%#{search_term}%", "%#{search_term}%" ]

      if clean_search.present?
        conditions << "REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g') LIKE ?"
        values     << "%#{clean_search}%"

        conditions << "REGEXP_REPLACE(cpf, '[^0-9]', '', 'g') LIKE ?"
        values     << "%#{clean_search}%"
      end

      @customers = @customers.where(conditions.join(" OR "), *values)
    end

    case params[:tier]
    when "vip"
      @customers = @customers.vip
    when "active"
      @customers = @customers.active
    end

    # Calcular totais antes da paginação
    # Para queries com GROUP BY, count retorna um hash, então usamos size para obter o total
    all_customers_for_totals = @customers.to_a
    @total_customers = all_customers_for_totals.size
    @total_revenue = all_customers_for_totals.sum { |c| c.total_spent.to_f }

    # Aplicar paginação
    @customers = @customers.page(params[:page]).per(per_page)
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

    respond_to do |format|
      if @customer.save

        if params[:guarantor].present? && params[:guarantor][:full_name].present?
          create_or_update_guarantor(@customer)
        end

        format.json { render json: { id: @customer.id, full_name: @customer.full_name }, status: :created }
        format.html { redirect_to customers_path, notice: "Cliente cadastrado com sucesso!" }
      else
        format.json { render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  rescue => e
    Rails.logger.error("Erro ao criar cliente: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    respond_to do |format|
      format.json { render json: { errors: [ "Erro interno ao processar a requisição." ] }, status: :unprocessable_entity }
      format.html { render :new, status: :unprocessable_entity }
    end
  end

  def update
    if @customer.update(customer_params)

      if params[:guarantor].present? && params[:guarantor][:full_name].present?
        create_or_update_guarantor(@customer)
      end

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
    permitted = params.require(:customer).permit(
      :full_name, :cpf, :birth_date, :phone_number,
      :email, :full_address, :notes, :phone
    )

    # Converte 'phone' para 'phone_number' se fornecido
    if permitted.key?(:phone)
      permitted[:phone_number] = permitted.delete(:phone)
    end

    permitted
  end


  def create_or_update_guarantor(customer)
    # SEGURANÇA: Usar strong parameters para filtrar dados do fiador
    permitted_guarantor = params.require(:guarantor).permit(
      :id, :full_name, :cpf, :phone, :relationship, :address
    )

    if permitted_guarantor[:id].present?
      guarantor = Guarantor.find(permitted_guarantor[:id])
      guarantor.update(permitted_guarantor.except(:id))
    else
      guarantor = Guarantor.create(permitted_guarantor.except(:id))
    end

    customer.update(guarantor: guarantor)
  end
end
