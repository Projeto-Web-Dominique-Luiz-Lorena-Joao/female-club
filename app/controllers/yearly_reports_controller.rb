class YearlyReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Determina o ano baseado nos parâmetros ou usa o ano atual
    @current_year = params[:year] ? params[:year].to_i : Date.today.year
    @start_date = Date.new(@current_year, 1, 1)
    @end_date = Date.new(@current_year, 12, 31)

    # Calcula o ano inicial baseado no primeiro registro
    @first_year = calculate_first_year
    @available_years = (@first_year..Date.today.year).to_a

    # Cache key baseado no ano e última atualização de vendas/despesas
    cache_key = yearly_report_cache_key

    # Usar cache para todo o cálculo de estatísticas
    cached_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      calculate_all_stats
    end

    # Atribuir dados do cache às variáveis de instância
    cached_data.each { |key, value| instance_variable_set("@#{key}", value) }
  end

  private

  def yearly_report_cache_key
    # Busca o timestamp da última atualização de vendas e despesas do ano
    last_sale_update = Sale.where(sale_date: @start_date..@end_date)
                           .maximum(:updated_at)&.to_i || 0
    last_expense_update = Expense.where(expense_date: @start_date..@end_date)
                                 .maximum(:updated_at)&.to_i || 0

    "yearly_report/#{@current_year}/#{last_sale_update}/#{last_expense_update}"
  end

  def calculate_all_stats
    # IMPORTANTE: calculate_monthly_breakdown deve vir antes de calculate_yearly_stats
    # porque best_month e worst_month dependem de @monthly_data
    calculate_monthly_breakdown
    calculate_yearly_stats
    calculate_quarterly_stats
    calculate_growth_trends

    # Retorna hash com todas as variáveis de instância calculadas
    {
      sales_this_year: @sales_this_year,
      total_revenue: @total_revenue,
      total_expenses: @total_expenses,
      net_profit: @net_profit,
      received: @received,
      pending: @pending,
      profit_margin: @profit_margin,
      sales_count: @sales_count,
      average_ticket: @average_ticket,
      best_month: @best_month,
      worst_month: @worst_month,
      top_products: @top_products,
      top_services: @top_services,
      top_customers: @top_customers,
      monthly_data: @monthly_data,
      chart_labels: @chart_labels,
      chart_revenue_data: @chart_revenue_data,
      chart_expenses_data: @chart_expenses_data,
      chart_profit_data: @chart_profit_data,
      quarterly_data: @quarterly_data,
      revenue_growth: @revenue_growth
    }
  end

  def calculate_yearly_stats
    # Vendas do ano (apenas pagas ou pendentes, não canceladas)
    # Eager load para evitar N+1 queries
    @sales_this_year = Sale.where(sale_date: @start_date..@end_date)
                           .where.not(status: 'cancelado')
                           .includes(:customer, sale_products: :product, sale_services: :service)

    # RECEITAS TOTAIS DO ANO
    @total_revenue = @sales_this_year.sum(:total_amount)

    # DESPESAS TOTAIS DO ANO (incluindo compra de produtos)
    @total_expenses = Expense.where(expense_date: @start_date..@end_date, status: 'ativa').sum(:amount)

    # LUCRO LÍQUIDO DO ANO
    # Fórmula simples: Receitas - Despesas
    # (As despesas já incluem a compra de produtos/supplies)
    @net_profit = @total_revenue - @total_expenses

    # RECEBIDO NO ANO
    @received = @sales_this_year.where(status: 'pago').sum(:total_amount)

    # PENDENTE NO ANO
    @pending = @sales_this_year.where(status: 'pendente').sum(:total_amount)

    # MARGEM DE LUCRO (%)
    @profit_margin = @total_revenue.positive? ? (@net_profit / @total_revenue * 100).round(2) : 0

    # QUANTIDADE DE VENDAS
    @sales_count = @sales_this_year.count

    # TICKET MÉDIO ANUAL
    @average_ticket = @sales_count.positive? ? @total_revenue / @sales_count : 0

    # MELHOR MÊS
    @best_month = calculate_best_month

    # PIOR MÊS
    @worst_month = calculate_worst_month

    # TOP 10 PRODUTOS DO ANO
    @top_products = calculate_top_products

    # TOP 10 SERVIÇOS DO ANO
    @top_services = calculate_top_services

    # TOP 5 CLIENTES DO ANO
    @top_customers = calculate_top_customers
  end

  def calculate_monthly_breakdown
    # Otimizado: Uma única query para todas as vendas do ano agrupadas por mês
    sales_by_month = Sale.where(sale_date: @start_date..@end_date)
                         .where.not(status: "cancelado")
                         .group("EXTRACT(MONTH FROM sale_date)")
                         .select("EXTRACT(MONTH FROM sale_date) as month,
                                  SUM(total_amount) as revenue,
                                  COUNT(*) as sales_count")
                         .each_with_object({}) { |record, hash| hash[record.month.to_i] = record }

    # Uma única query para todas as despesas do ano agrupadas por mês
    expenses_by_month = Expense.where(expense_date: @start_date..@end_date, status: "ativa")
                               .group("EXTRACT(MONTH FROM expense_date)")
                               .select("EXTRACT(MONTH FROM expense_date) as month,
                                        SUM(amount) as expenses")
                               .each_with_object({}) { |record, hash| hash[record.month.to_i] = record }

    @monthly_data = (1..12).map do |month|
      sale_data = sales_by_month[month]
      expense_data = expenses_by_month[month]

      revenue = sale_data&.revenue&.to_f || 0
      expenses = expense_data&.expenses&.to_f || 0
      sales_count = sale_data&.sales_count&.to_i || 0

      {
        month: month,
        month_name: I18n.t("date.month_names")[month],
        revenue: revenue,
        expenses: expenses,
        profit: revenue - expenses,
        sales_count: sales_count
      }
    end

    @chart_labels = @monthly_data.map { |d| d[:month_name][0..2] }
    @chart_revenue_data = @monthly_data.map { |d| d[:revenue] }
    @chart_expenses_data = @monthly_data.map { |d| d[:expenses] }
    @chart_profit_data = @monthly_data.map { |d| d[:profit] }
  end

  def calculate_quarterly_stats
    # Otimizado: Uma única query para vendas agrupadas por trimestre
    sales_by_quarter = Sale.where(sale_date: @start_date..@end_date)
                           .where.not(status: "cancelado")
                           .group("CEIL(EXTRACT(MONTH FROM sale_date) / 3.0)")
                           .select("CEIL(EXTRACT(MONTH FROM sale_date) / 3.0) as quarter,
                                    SUM(total_amount) as revenue")
                           .each_with_object({}) { |record, hash| hash[record.quarter.to_i] = record }

    # Uma única query para despesas agrupadas por trimestre
    expenses_by_quarter = Expense.where(expense_date: @start_date..@end_date, status: "ativa")
                                 .group("CEIL(EXTRACT(MONTH FROM expense_date) / 3.0)")
                                 .select("CEIL(EXTRACT(MONTH FROM expense_date) / 3.0) as quarter,
                                          SUM(amount) as expenses")
                                 .each_with_object({}) { |record, hash| hash[record.quarter.to_i] = record }

    @quarterly_data = (1..4).map do |quarter|
      sale_data = sales_by_quarter[quarter]
      expense_data = expenses_by_quarter[quarter]

      revenue = sale_data&.revenue&.to_f || 0
      expenses = expense_data&.expenses&.to_f || 0

      {
        quarter: quarter,
        revenue: revenue,
        expenses: expenses,
        profit: revenue - expenses
      }
    end
  end

  def calculate_growth_trends
    # Compara com o ano anterior se disponível
    previous_year = @current_year - 1
    prev_start = Date.new(previous_year, 1, 1)
    prev_end = Date.new(previous_year, 12, 31)

    prev_revenue = Sale.where(sale_date: prev_start..prev_end)
                      .where.not(status: "cancelado")
                      .sum(:total_amount)

    if prev_revenue.positive?
      @revenue_growth = ((@total_revenue - prev_revenue) / prev_revenue * 100).round(2)
    else
      @revenue_growth = 0
    end
  end

  def calculate_best_month
    best = @monthly_data.max_by { |d| d[:revenue] }
    best ? { name: best[:month_name], revenue: best[:revenue] } : nil
  end

  def calculate_worst_month
    worst = @monthly_data.min_by { |d| d[:revenue] }
    worst ? { name: worst[:month_name], revenue: worst[:revenue] } : nil
  end

  def calculate_top_products
    # Otimizado com SQL agregado ao invés de iteração em Ruby
    SaleProduct.joins(:sale, :product)
               .where(sales: { sale_date: @start_date..@end_date })
               .where.not(sales: { status: "cancelado" })
               .group("products.name")
               .select("products.name as product_name,
                        SUM(sale_products.quantity) as total_quantity,
                        SUM(sale_products.unit_price * sale_products.quantity) as total_revenue")
               .order("total_revenue DESC")
               .limit(10)
               .map { |sp| [ sp.product_name, { quantity: sp.total_quantity.to_i, revenue: sp.total_revenue.to_f } ] }
  end

  def calculate_top_services
    # Otimizado com SQL agregado ao invés de iteração em Ruby
    SaleService.joins(:sale, :service)
                .where(sales: { sale_date: @start_date..@end_date })
                .where.not(sales: { status: "cancelado" })
                .group("services.name")
                .select("services.name as service_name,
                         SUM(sale_services.quantity) as total_quantity,
                         SUM(sale_services.unit_price * sale_services.quantity) as total_revenue")
                .order("total_revenue DESC")
                .limit(10)
                .map { |ss| [ ss.service_name, { quantity: ss.total_quantity.to_i, revenue: ss.total_revenue.to_f } ] }
  end

  def calculate_top_customers
    # Otimizado com SQL agregado ao invés de iteração em Ruby
    Sale.joins(:customer)
        .where(sale_date: @start_date..@end_date)
        .where.not(status: "cancelado")
        .group("customers.id, customers.full_name")
        .select("customers.full_name,
                 COUNT(sales.id) as sales_count,
                 SUM(sales.total_amount) as total_revenue")
        .order("total_revenue DESC")
        .limit(5)
        .map { |s| [ s.full_name, { sales_count: s.sales_count.to_i, revenue: s.total_revenue.to_f } ] }
  end

  def calculate_first_year
    first_sale = Sale.order(:sale_date).first
    first_expense = Expense.order(:expense_date).first

    years = []
    years << first_sale.sale_date.year if first_sale
    years << first_expense.expense_date.year if first_expense

    years.empty? ? Date.today.year : years.min
  end
end
