# app/controllers/suppliers_controller.rb
class SuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier, only: [ :show, :edit, :update, :destroy, :reactivate ]

  def index
    @suppliers = Supplier.all.order(created_at: :desc)

    # Filtro por categoria
    if params[:category].present?
      @suppliers = @suppliers.by_category(params[:category])
    end

    # Filtro por status
    if params[:status].present?
      case params[:status]
      when "ativo"
        @suppliers = @suppliers.active
      when "inativo"
        @suppliers = @suppliers.inactive
      end
    end

    if params[:search].present?
      search_term = sanitize_search(params[:search])
    clean_search = search_term.gsub(/\D/, "")

    conditions = [ "legal_name ILIKE ? OR trade_name ILIKE ? OR email ILIKE ?" ]
    values = [ "%#{search_term}%", "%#{search_term}%", "%#{search_term}%" ]

    # Só adiciona busca no telefone se tiver números
    if clean_search.present?
      conditions << "REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g') LIKE ?"
      values << "%#{clean_search}%"
    end

    @suppliers = @suppliers.where(conditions.join(" OR "), *values)
    end

    # Estatísticas
    @total_suppliers = @suppliers.count
    # @active_suppliers = Supplier.active.count
    # @total_items = StockItem.count
    # @total_stock_value = StockItem.sum('quantity * sale_price')
    @suppliers = @suppliers.page(params[:page]).per(per_page)
  end

  def show
    # @supplied_items = @supplier.stock_items.order(created_at: :desc).limit(20)
    # @recent_movements = @supplier.stock_movements.recent.limit(10)
  end

  def new
    @supplier = Supplier.new
  end

  def edit
  end

  def create
    @supplier = Supplier.new(supplier_params)

    if @supplier.save
      redirect_to suppliers_path, notice: "Fornecedor cadastrado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to suppliers_path, notice: "Fornecedor atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @supplier.update(status: "inativo")
    redirect_to suppliers_path, notice: "Fornecedor inativado com sucesso. Você pode reativá-lo quando quiser."
  end

  def reactivate
    if @supplier.update(status: "ativo")
      redirect_to supplier_path(@supplier), notice: "Fornecedor reativado com sucesso. Você pode inativá-lo quando quiser."
    else
      redirect_to supplier_path(@supplier), alert: "Não foi possível reativar o fornecedor."
    end
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(
      :legal_name, :trade_name, :phone_number, :email,
      :full_address, :product_category, :status, :notes
    )
  end
end
