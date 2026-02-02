class GuarantorsController < ApplicationController

  before_action :set_guarantor, only: [:show, :edit, :update, :destroy]

  def index
    # PERFORMANCE: Eager loading de customer para evitar N+1
    @guarantors = Guarantor.includes(:customer).order(created_at: :desc)

    if params[:search].present?

      search_term = sanitize_search(params[:search])
      clean_search = search_term.gsub(/\D/, "")

      conditions = [
        'guarantors.full_name ILIKE ?',
        'customers.full_name ILIKE ?'
      ]
      values = ["%#{search_term}%", "%#{search_term}%"]

      if clean_search.present?
        conditions << "REGEXP_REPLACE(guarantors.cpf, '[^0-9]', '', 'g') LIKE ?"
        values << "%#{clean_search}%"

        conditions << "REGEXP_REPLACE(phone, '[^0-9]', '', 'g') LIKE ?"
        values << "%#{clean_search}%"
      end

      # FIX: Usar left_joins para permitir busca por nome do cliente
      @guarantors = @guarantors.left_joins(:customer).where(conditions.join(' OR '), *values)
    end

    if params[:status].present?
    @guarantors = @guarantors.where(status: params[:status])
  end

      @total_guarantors = Guarantor.count
      @active_guarantors = Guarantor.where(status: 'ativo').count
      @guarantors = @guarantors.page(params[:page]).per(per_page)
  end

  def show
  end

  def new
    @guarantor = Guarantor.new
  end

  def create
    @guarantor = Guarantor.new(guarantor_params)

    if @guarantor.save
      # Processar associação com cliente se fornecido
      if params[:customer_association_id].present?
        associate_customer_result = associate_customer_to_guarantor(@guarantor, params[:customer_association_id])

        unless associate_customer_result[:success]
          @guarantor.destroy
          flash.now[:alert] = associate_customer_result[:error]
          render :new, status: :unprocessable_entity
          return
        end
      end

      redirect_to guarantor_path(@guarantor),
                  notice: "Fiador cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @guarantor.update(guarantor_params)
      # Processar associação com cliente se fornecido
      if params[:customer_association_id].present?
        associate_customer_result = associate_customer_to_guarantor(@guarantor, params[:customer_association_id])

        unless associate_customer_result[:success]
          flash[:alert] = associate_customer_result[:error]
          redirect_to edit_guarantor_path(@guarantor)
          return
        end
      elsif params[:customer_association_id] == ""
        # Remover associação se campo estiver vazio
        remove_customer_association(@guarantor)
      end

      redirect_to guarantors_path, notice: 'Fiador atualizado com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @guarantor.destroy
    redirect_to guarantors_path, notice: 'Fiador excluído com sucesso!'
  end

  def search_customers
    query = params[:query].to_s.strip
    @customers = Customer.where("full_name ILIKE ?", "%#{query}%")
                        .order(:full_name)
                        .limit(10)

    render json: @customers.map { |c| { id: c.id, name: c.full_name } }
  end

  private

  def set_guarantor
    # PERFORMANCE: Eager loading para show/edit
    @guarantor = Guarantor.includes(:customer).find(params[:id])
  end

  def guarantor_params
    params.require(:guarantor).permit(
      :full_name,
      :cpf,
      :phone,
      :address,
      :relationship,
      :status
    )
  end

  def associate_customer_to_guarantor(guarantor, customer_id)
    customer = Customer.find_by(id: customer_id)

    unless customer
      return { success: false, error: "Cliente não encontrado." }
    end

    # Verifica se o cliente já tem outro fiador
    if customer.guarantor.present? && customer.guarantor != guarantor
      return {
        success: false,
        error: "Este cliente já possui um fiador (#{customer.guarantor.full_name}). Por favor, edite ou exclua o fiador dele antes de associar este."
      }
    end

    # Remove a associação anterior (se houver outro cliente associado a este fiador)
    if guarantor.customer.present? && guarantor.customer != customer
      guarantor.customer.update(guarantor: nil)
    end

    # Associa o fiador ao cliente
    customer.update(guarantor: guarantor)

    { success: true }
  end

  def remove_customer_association(guarantor)
    if guarantor.customer.present?
      guarantor.customer.update(guarantor: nil)
    end
  end
end