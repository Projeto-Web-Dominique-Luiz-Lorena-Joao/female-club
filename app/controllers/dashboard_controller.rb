# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @vendas_mes = calculate_monthly_sales
    @total_vendas = count_total_sales
    @clientes_ativos = count_active_customers
    @estoque_baixo = count_low_stock_items
    @vendas_data = generate_sales_chart_data
    @produtos_mais_vendidos = get_top_selling_products
  end

  private

  def calculate_monthly_sales
    # Vendas do mês atual (apenas vendas pagas)
    Sale.where(
      sale_date: Date.current.beginning_of_month..Date.current.end_of_month,
      status: 'pago'
    ).sum(:total_amount).to_f
  end

  def count_total_sales
    # Total de vendas no mês atual
    Sale.where(
      sale_date: Date.current.beginning_of_month..Date.current.end_of_month
    ).count
  end

  def count_active_customers
    # Clientes que fizeram pelo menos uma compra nos últimos 30 dias
    Customer.joins(:sales)
            .where('sales.sale_date >= ?', 30.days.ago)
            .distinct
            .count
  end

  def count_low_stock_items
    # Produtos com quantidade menor que 10 unidades (você pode ajustar esse valor)
    Product.where('quantity_in < ?', 10).count
  end

  def generate_sales_chart_data
    # Dados dos últimos 8 meses para o gráfico
    data = []
    
    (7.downto(0)).each do |months_ago|
      date = months_ago.months.ago
      start_date = date.beginning_of_month
      end_date = date.end_of_month
      
      total = Sale.where(
        sale_date: start_date..end_date,
        status: 'pago'
      ).sum(:total_amount).to_f
      
      data << total
    end
    
    data
  end

  def get_top_selling_products
    # Top 5 produtos mais vendidos no mês atual
    top_products = SaleProduct.joins(:sale, :product)
                               .where('sales.sale_date >= ? AND sales.status = ?', 
                                      Date.current.beginning_of_month, 'pago')
                               .group('products.id', 'products.name')
                               .select(
                                 'products.name as product_name',
                                 'SUM(sale_products.quantity) as total_quantity',
                                 'SUM(sale_products.quantity * sale_products.unit_price) as total_value'
                               )
                               .order('total_value DESC')
                               .limit(5)

    top_products.map do |item|
      {
        nome: item.product_name,
        unidades: item.total_quantity.to_i,
        valor: item.total_value.to_f
      }
    end
  end
end