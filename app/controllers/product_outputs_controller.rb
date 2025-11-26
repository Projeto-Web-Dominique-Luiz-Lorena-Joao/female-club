class ProductOutputsController < ApplicationController
  before_action :set_product_output, only: [:show, :edit, :update, :destroy]
  before_action :set_product, only: [:new, :create]
  skip_before_action :set_product, only: [:search_products, :list_products, :new]

  def index
    @product_outputs = ProductOutput.recent
    @product_outputs = @product_outputs.by_product(params[:product_id]) if params[:product_id].present?
    @product_outputs = @product_outputs.by_output_type(params[:output_type]) if params[:output_type].present?
    @product_outputs = @product_outputs.by_date_range(params[:start_date].to_date, params[:end_date].to_date) if params[:start_date].present? && params[:end_date].present?
  end

  def show
  end

  def new
    @product_output = ProductOutput.new
  end

  def create
    @product_output = ProductOutput.new(product_output_params)
    @product_output.created_by = current_user

    if @product_output.save
      redirect_to product_outputs_path, notice: "Saída de produto registrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product_output.update(product_output_params)
      redirect_to @product_output, notice: "Saída de produto atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product_output.destroy
    redirect_to product_outputs_url, notice: "Saída de produto removida com sucesso."
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

  private

  def set_product_output
    @product_output = ProductOutput.find(params[:id])
  end

  def set_product
    @product = Product.find(params[:product_id]) if params[:product_id].present?
  end

  def product_output_params
    params_hash = params.require(:product_output).permit(:product_id, :quantity, :output_type, :date_output, :date_output_time, :notes)

    # Combinar data e hora se ambas forem fornecidas
    if params_hash[:date_output].present? && params_hash[:date_output_time].present?
      date = params_hash[:date_output]
      time = params_hash[:date_output_time]
      params_hash[:date_output] = "#{date} #{time}:00"
    end

    params_hash.except(:date_output_time)
  end
end
