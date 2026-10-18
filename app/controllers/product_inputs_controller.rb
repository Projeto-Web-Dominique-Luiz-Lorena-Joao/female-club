class ProductInputsController < ApplicationController
  before_action :set_product_input, only: [ :show, :edit, :update, :destroy ]
  before_action :set_product, only: [ :new, :create ]
  skip_before_action :set_product, only: [ :search_products, :list_products, :search_suppliers, :list_suppliers, :new ]

  def index
    @product_inputs = ProductInput.recent
    @product_inputs = @product_inputs.by_product(params[:product_id]) if params[:product_id].present?
    @product_inputs = @product_inputs.by_supplier(params[:supplier_id]) if params[:supplier_id].present?
    start_date = parse_filter_date(params[:start_date])
    end_date = parse_filter_date(params[:end_date])
    @product_inputs = @product_inputs.by_date_range(start_date, end_date) if start_date && end_date
    @product_inputs = @product_inputs.page(params[:page]).per(per_page)
  end

  def show
  end

  def new
    @product_input = ProductInput.new
  end

  def create
    @product_input = ProductInput.new(product_input_params)
    @product_input.created_by = current_user

    if @product_input.save
      redirect_to product_inputs_path, notice: "Entrada de produto registrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product_input.update(product_input_params)
      redirect_to @product_input, notice: "Entrada de produto atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product_input.destroy
    redirect_to product_inputs_url, notice: "Entrada de produto removida com sucesso."
  end

  def search_products
    query = params[:query].to_s.strip
    @products = Product.active
                      .where("name ILIKE ? OR code ILIKE ?", "%#{query}%", "%#{query}%")
                      .order(:name)
                      .limit(10)

    render json: @products.map { |p| { id: p.id, name: p.name, subtitle: "Est. Atual: #{p.quantity.to_i}" } }
  end

  def list_products
    @products = Product.active.order(:name)
    render json: @products.map { |p| { id: p.id, name: p.name, subtitle: "Est. Atual: #{p.quantity.to_i}" } }
  end

  def search_suppliers
    query = params[:query].to_s.strip
    @suppliers = Supplier.where(status: "ativo")
                        .where("legal_name ILIKE ?", "%#{query}%")
                        .order(:legal_name)
                        .limit(10)

    render json: @suppliers.map { |s| { id: s.id, name: s.legal_name } }
  end

  def list_suppliers
    @suppliers = Supplier.where(status: "ativo").order(:legal_name)
    render json: @suppliers.map { |s| { id: s.id, name: s.legal_name } }
  end

  private

  def set_product_input
    @product_input = ProductInput.find(params[:id])
  end

  def set_product
    @product = Product.find(params[:product_id]) if params[:product_id].present?
  end

  def product_input_params
    params_hash = params.require(:product_input).permit(:product_id, :supplier_id, :quantity, :unit_cost, :date_input, :date_input_time, :invoice_number, :notes)

    # Converter unit_cost de formato brasileiro (1.234,56) para formato de banco de dados (1234.56)
    if params_hash[:unit_cost].present?
      unit_cost_str = params_hash[:unit_cost].to_s
      # Remove ponto (separador de milhar) e substitui vírgula por ponto
      unit_cost_str = unit_cost_str.gsub(".", "").gsub(",", ".")
      params_hash[:unit_cost] = unit_cost_str
    end

    # Combinar data e hora se ambas forem fornecidas
    if params_hash[:date_input].present? && params_hash[:date_input_time].present?
      date = params_hash[:date_input]
      time = params_hash[:date_input_time]
      params_hash[:date_input] = "#{date} #{time}:00"
    end

    params_hash.except(:date_input_time)
  end
end
