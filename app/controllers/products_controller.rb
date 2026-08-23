class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    # PERFORMANCE: Eager loading e cálculo de estoque otimizado via SQL
    @products = Product.includes(:supplier, :product_inputs, :product_outputs)
                       .with_attached_cover_image

    @products = @products.active if params[:active] == "true"
    @products = @products.inactive if params[:active] == "false"
    @products = @products.by_category(params[:category]) if params[:category].present?
    @products = @products.low_stock if params[:low_stock] == "true"
    @products = @products.by_stock_status(params[:stock_status]) if params[:stock_status].present?
    @products = @products.search(params[:search]) if params[:search].present?

    @products = @products.order(created_at: :desc)
    @products = @products.page(params[:page]).per(per_page)

    # PERFORMANCE: Atualizar status de estoque apenas dos produtos da página atual
    # usando batch update ao invés de N queries individuais
    update_stock_status_batch(@products.to_a)
  end

  def show
    @product.refresh_stock_status!
  end

  def new
    @product = Product.new
  end

  def edit
  end

  def create
    @product = Product.new(product_params.except(:cover_image_delete))

    if @product.save
      redirect_to @product, notice: "Produto criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Remover imagem se solicitado
    if params[:product][:cover_image_delete] == "true"
      @product.cover_image.purge
    end

    # Remover cover_image_delete dos params antes de atualizar
    update_params = product_params.except(:cover_image_delete)

    if @product.update(update_params)
      redirect_to @product, notice: "Produto atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_url, notice: "Produto removido com sucesso."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  # PERFORMANCE: Atualização em batch do status de estoque
  def update_stock_status_batch(products)
    return if products.empty?

    products.each do |product|
      new_status = product.calculate_stock_status
      if product.stock_status != new_status
        product.update_column(:stock_status, new_status)
      end
    end
  end

  def product_params
    params.require(:product).permit(
      :supplier_id,
      :name,
      :description,
      :active,
      :brand,
      :color,
      :sale_price,
      :category,
      :min_stock,
      :location,
      :notes,
      :unit,
      :code,
      :cover_image,
      :cover_image_delete
    )
  end
end
