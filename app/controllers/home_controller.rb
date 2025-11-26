class HomeController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :authenticate_user!

  def dashboard
    # Vendas do mês atual (excluindo canceladas)
    current_month_start = Date.today.beginning_of_month
    current_month_end = Date.today.end_of_month

    vendas_mes = Sale.where.not(status: 'cancelado')
                     .where(sale_date: current_month_start..current_month_end)
                     .sum(:total_amount)
    @vendas_mes = number_with_delimiter(vendas_mes.round(2).to_s, delimiter: '.', separator: ',')

    # Total de vendas (quantidade, excluindo canceladas)
    @total_vendas = Sale.where.not(status: 'cancelado').count

    # Clientes ativos (com vendas não canceladas)
    @clientes_ativos = Customer.joins(:sales)
                               .where.not(sales: { status: 'cancelado' })
                               .distinct
                               .count

    # Estoque baixo (produtos com quantidade <= min_stock)
    @estoque_baixo = Product.select { |p| p.low_stock? }.count

    # Dados do gráfico de vendas (últimos 8 meses, excluindo canceladas)
    @vendas_data = (0..7).map do |months_ago|
      date = months_ago.months.ago
      month_start = date.beginning_of_month
      month_end = date.end_of_month
      Sale.where.not(status: 'cancelado')
          .where(sale_date: month_start..month_end)
          .sum(:total_amount)
    end

    # Produtos mais vendidos (considerando apenas vendas não canceladas)
    @produtos_mais_vendidos = calculate_top_products
  end

  private

  def calculate_top_products
    SaleProduct.joins(:sale, :product)
               .where.not(sales: { status: 'cancelado' })
               .select('products.name, COUNT(sale_products.id) as quantidade, SUM(sale_products.quantity * sale_products.unit_price) as valor')
               .group('products.name')
               .order('quantidade DESC')
               .limit(5)
               .map do |sp|
                 {
                   nome: sp.name,
                   unidades: sp.quantidade,
                   valor: number_to_currency(sp.valor || 0, unit: '', precision: 2, delimiter: '.', separator: ',')
                 }
               end
  end
end