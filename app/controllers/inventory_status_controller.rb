class InventoryStatusController < ApplicationController
  def index
    @products = Product.where(active: true)
                       .select(:id, :name, :code, :brand, :category, :quantity, :min_stock, :stock_status, :sale_price, :purchase_price, :active)
                       .order(:name)
                       .page(params[:page])
                       .per(20)

    # Filtros opcionais
    if params[:stock_status].present?
      @products = @products.where(stock_status: params[:stock_status])
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @products = @products.where("name ILIKE ? OR code ILIKE ?", search_term, search_term)
    end

    # Estatísticas
    @total_products = Product.where(active: true).count
    @critical_stock = Product.where(active: true, stock_status: 'critico').count
    @low_stock = Product.where(active: true, stock_status: 'baixo').count
    @out_of_stock = Product.where(active: true, stock_status: 'fora_de_estoque').count
    @in_stock = Product.where(active: true, stock_status: 'em_estoque').count
  end
end
