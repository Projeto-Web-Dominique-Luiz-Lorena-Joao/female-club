class InventoryStatusController < ApplicationController
  def index
    @products = Product.where(active: true)
                       .includes(:product_inputs, :product_outputs)
                       .order(:name)

    # Atualizar status de estoque de todos os produtos para garantir consistência
    Product.where(active: true).each(&:refresh_stock_status!)

    # Filtros opcionais
    if params[:stock_status].present?
      @products = @products.where(stock_status: params[:stock_status])
    end

    if params[:search].present?
      search_term = "%#{sanitize_search(params[:search])}%"
      @products = @products.where("name ILIKE ? OR code ILIKE ?", search_term, search_term)
    end

    # Paginação
    @products = @products.page(params[:page]).per(per_page)

    # Estatísticas
    @total_products = Product.where(active: true).count
    @critical_stock = Product.where(active: true, stock_status: "critico").count
    @low_stock = Product.where(active: true, stock_status: "baixo").count
    @out_of_stock = Product.where(active: true, stock_status: "fora_de_estoque").count
    @in_stock = Product.where(active: true, stock_status: "em_estoque").count
  end
end
