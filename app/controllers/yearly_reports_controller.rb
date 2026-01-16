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

    # IMPORTANTE: calculate_monthly_breakdown deve vir antes de calculate_yearly_stats
    # porque best_month e worst_month dependem de @monthly_data
    calculate_monthly_breakdown
    calculate_yearly_stats
    calculate_quarterly_stats
    calculate_growth_trends
  end

  private

  def calculate_yearly_stats
    # Vendas do ano (apenas pagas ou pendentes, não canceladas)
    @sales_this_year = Sale.where(sale_date: @start_date..@end_date)
                           .where.not(status: 'cancelado')

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
    @monthly_data = (1..12).map do |month|
      month_start = Date.new(@current_year, month, 1)
      month_end = month_start.end_of_month

      sales = Sale.where(sale_date: month_start..month_end)
                  .where.not(status: 'cancelado')

      revenue = sales.sum(:total_amount)
      expenses = Expense.where(expense_date: month_start..month_end, status: 'ativa').sum(:amount)

      # Calcular lucro líquido: Receitas - Despesas
      # (As despesas já incluem a compra de produtos/supplies)
      net_profit = revenue - expenses

      {
        month: month,
        month_name: I18n.t('date.month_names')[month],
        revenue: revenue,
        expenses: expenses,
        profit: net_profit,
        sales_count: sales.count
      }
    end

    @chart_labels = @monthly_data.map { |d| d[:month_name][0..2] } # Abreviar meses
    @chart_revenue_data = @monthly_data.map { |d| d[:revenue] }
    @chart_expenses_data = @monthly_data.map { |d| d[:expenses] }
    @chart_profit_data = @monthly_data.map { |d| d[:profit] }
  end

  def calculate_quarterly_stats
    @quarterly_data = (1..4).map do |quarter|
      start_month = (quarter - 1) * 3 + 1
      end_month = start_month + 2

      quarter_start = Date.new(@current_year, start_month, 1)
      quarter_end = Date.new(@current_year, end_month, 1).end_of_month

      sales = Sale.where(sale_date: quarter_start..quarter_end)
                  .where.not(status: 'cancelado')

      revenue = sales.sum(:total_amount)
      expenses = Expense.where(expense_date: quarter_start..quarter_end, status: 'ativa').sum(:amount)

      # Calcular lucro líquido: Receitas - Despesas
      # (As despesas já incluem a compra de produtos/supplies)
      net_profit = revenue - expenses

      {
        quarter: quarter,
        revenue: revenue,
        expenses: expenses,
        profit: net_profit
      }
    end
  end

  def calculate_growth_trends
    # Compara com o ano anterior se disponível
    previous_year = @current_year - 1
    prev_start = Date.new(previous_year, 1, 1)
    prev_end = Date.new(previous_year, 12, 31)

    prev_revenue = Sale.where(sale_date: prev_start..prev_end)
                      .where.not(status: 'cancelado')
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
    product_sales = {}

    @sales_this_year.each do |sale|
      sale.sale_products.each do |sp|
        next unless sp.product

        product_name = sp.product.name
        product_sales[product_name] ||= { quantity: 0, revenue: 0 }
        product_sales[product_name][:quantity] += sp.quantity
        product_sales[product_name][:revenue] += sp.unit_price * sp.quantity
      end
    end

    product_sales.sort_by { |_, data| -data[:revenue] }.first(10)
  end

  def calculate_top_services
    service_sales = {}

    @sales_this_year.each do |sale|
      sale.sale_services.each do |ss|
        next unless ss.service

        service_name = ss.service.name
        service_sales[service_name] ||= { quantity: 0, revenue: 0 }
        service_sales[service_name][:quantity] += ss.quantity
        service_sales[service_name][:revenue] += ss.total_price
      end
    end

    service_sales.sort_by { |_, data| -data[:revenue] }.first(10)
  end

  def calculate_top_customers
    customer_sales = {}

    @sales_this_year.each do |sale|
      next unless sale.customer

      customer_name = sale.customer.full_name
      customer_sales[customer_name] ||= { sales_count: 0, revenue: 0 }
      customer_sales[customer_name][:sales_count] += 1
      customer_sales[customer_name][:revenue] += sale.total_amount
    end

    customer_sales.sort_by { |_, data| -data[:revenue] }.first(5)
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
