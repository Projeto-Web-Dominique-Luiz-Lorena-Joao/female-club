class HomeController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # PERFORMANCE: Atualização otimizada de status de estoque via SQL
    update_stock_status_batch

    # Período do mês atual
    @current_month_start = Date.current.beginning_of_month
    @current_month_end = Date.current.end_of_month
    @last_month_start = 1.month.ago.beginning_of_month
    @last_month_end = 1.month.ago.end_of_month

    # KPIs com dados reais
    calculate_kpis

    # Dados do gráfico de vendas (últimos 8 meses)
    calculate_sales_chart_data

    # Produtos mais vendidos do mês
    calculate_top_products
  end

  private

  def calculate_kpis
    # Vendas do mês atual (não canceladas)
    vendas_mes_atual = Sale.where(sale_date: @current_month_start..@current_month_end)
                           .where.not(status: 'cancelado')
    @vendas_mes = vendas_mes_atual.sum(:total_amount)
    @total_vendas = vendas_mes_atual.count

    # Vendas do mês anterior para comparação
    vendas_mes_anterior = Sale.where(sale_date: @last_month_start..@last_month_end)
                              .where.not(status: 'cancelado')
    @vendas_mes_anterior = vendas_mes_anterior.sum(:total_amount)
    @total_vendas_anterior = vendas_mes_anterior.count

    # Calcular variação percentual
    @variacao_vendas = calculate_variation(@vendas_mes, @vendas_mes_anterior)
    @variacao_total = calculate_variation(@total_vendas, @total_vendas_anterior)

    # Clientes ativos (com compra nos últimos 3 meses)
    @clientes_ativos = Customer.joins(:sales)
                               .where(sales: { sale_date: 3.months.ago..Date.current })
                               .where.not(sales: { status: 'cancelado' })
                               .distinct
                               .count

    clientes_ativos_anterior = Customer.joins(:sales)
                                       .where(sales: { sale_date: 4.months.ago..1.month.ago })
                                       .where.not(sales: { status: 'cancelado' })
                                       .distinct
                                       .count
    @variacao_clientes = calculate_variation(@clientes_ativos, clientes_ativos_anterior)

    # Estoque baixo
    @estoque_baixo = Product.where(stock_status: ['baixo', 'critico']).count
  end

  def calculate_sales_chart_data
    # Últimos 8 meses de vendas
    @chart_labels = []
    @vendas_data = []

    8.downto(1) do |i|
      month_date = (i - 1).months.ago
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      @chart_labels << I18n.l(month_start, format: '%b')

      total = Sale.where(sale_date: month_start..month_end)
                  .where.not(status: 'cancelado')
                  .sum(:total_amount)
      @vendas_data << total.to_f
    end
  end

  def calculate_top_products
    # Top 5 produtos mais vendidos no mês atual
    product_sales = {}

    Sale.where(sale_date: @current_month_start..@current_month_end)
        .where.not(status: 'cancelado')
        .includes(sale_products: :product)
        .find_each do |sale|
      sale.sale_products.each do |sp|
        next unless sp.product

        product_name = sp.product.name
        product_sales[product_name] ||= { unidades: 0, valor: 0 }
        product_sales[product_name][:unidades] += sp.quantity
        product_sales[product_name][:valor] += sp.unit_price * sp.quantity
      end
    end

    @produtos_mais_vendidos = product_sales
      .sort_by { |_, data| -data[:valor] }
      .first(5)
      .map do |nome, data|
        {
          nome: nome,
          unidades: data[:unidades],
          valor: data[:valor]
        }
      end
  end

  def calculate_variation(current, previous)
    return 0 if previous.zero?
    ((current - previous).to_f / previous * 100).round(1)
  end

  # PERFORMANCE: Atualização de status em batch via SQL
  def update_stock_status_batch
    Product.includes(:product_inputs, :product_outputs).find_each(batch_size: 100) do |product|
      new_status = product.calculate_stock_status
      product.update_column(:stock_status, new_status) if product.stock_status != new_status
    end
  end
end