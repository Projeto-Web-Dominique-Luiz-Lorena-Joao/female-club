class ProductsController < ApplicationController

  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    @products = Product.all

    @products = @products.active if params[:active] == 'true'
    @products = @products.inactive if params[:active] == 'false'
    @products = @products.by_category(params[:category]) if params[:category].present?
    @products = @products.low_stock if params[:low_stock] == 'true'
    @products = @products.search(params[:search]) if params[:search].present?

    @products = @products.order(created_at: :desc)

    # Paginação (se usar kaminari ou pagy)
    # @products = @products.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @product = Product.new
  end

  def edit
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to @product, notice: 'Produto criado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: 'Produto atualizado com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_url, notice: 'Produto removido com sucesso.'
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    # Handle cover image deletion before permit
    if params[:product][:cover_image_delete] == "true"
      @product.cover_image.purge if @product.cover_image.attached?
    end

    permitted = params.require(:product).permit(
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
      :cover_image
    )

    # Convert active string to boolean
    if permitted[:active].present?
      permitted[:active] = ActiveModel::Type::Boolean.new.cast(permitted[:active])
    end

    permitted
  end
end