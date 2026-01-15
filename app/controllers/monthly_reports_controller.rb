class MonthlyReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Determina o mês atual baseado nos parâmetros ou usa o mês atual
    if params[:year] && params[:month]
      @current_month = Date.new(params[:year].to_i, params[:month].to_i, 1)
    elsif params[:month]
      @current_month = params[:month].to_date
    else
      @current_month = Date.today.beginning_of_month
    end

    @start_date = @current_month.beginning_of_month
    @end_date = @current_month.end_of_month

    # Calcula o ano inicial baseado no primeiro registro
    @first_year = calculate_first_year
    @available_years = (@first_year..Date.today.year).to_a

    calculate_monthly_stats
    calculate_daily_cash_flow
    calculate_projections
    calculate_top_products_and_services
  end

  private

  def calculate_monthly_stats
    # Vendas do mês (apenas pagas ou pendentes, não canceladas)
    @sales_this_month = Sale.where(sale_date: @start_date..@end_date)
                             .where.not(status: 'cancelado')

    # LUCRO LÍQUIDO
    # Produtos: preço de venda - custo
    # Serviços: valor integral
    @net_profit = calculate_net_profit

    # RECEITAS TOTAIS (soma de todas as vendas não canceladas)
    @total_revenue = @sales_this_month.sum(:total_amount)

    # DESPESAS TOTAIS (apenas despesas ativas)
    @total_expenses = Expense.where(expense_date: @start_date..@end_date)
                             .where(status: 'ativa')
                             .sum(:amount)

    # RECEBIDO (vendas já pagas)
    @received = @sales_this_month.where(status: 'pago').sum(:total_amount)

    # ATRASADOS (vendas pendentes com data de vencimento passada)
    @overdue_sales = @sales_this_month.where(status: 'pendente')
                                      .where('due_date < ?', Date.today)
    @overdue_amount = @overdue_sales.sum(:total_amount)
    @overdue_count = @overdue_sales.count

    # Vendas pendentes (a receber no futuro)
    @pending_amount = @sales_this_month.where(status: 'pendente')
                                       .where('due_date >= ? OR due_date IS NULL', Date.today)
                                       .sum(:total_amount)
  end

  def calculate_net_profit
    profit = 0

    @sales_this_month.each do |sale|
      # Lucro dos produtos: preço de venda - custo
      sale.sale_products.each do |sale_product|
        next unless sale_product.product

        # Custo médio do produto (baseado nas entradas)
        cost_per_unit = calculate_product_cost(sale_product.product)
        revenue = sale_product.unit_price * sale_product.quantity
        cost = cost_per_unit * sale_product.quantity
        profit += (revenue - cost)
      end

      # Lucro dos serviços: valor integral
      sale.sale_services.each do |sale_service|
        profit += sale_service.total_price
      end
    end

    profit
  end

  def calculate_product_cost(product)
    # Calcula o custo médio ponderado do produto
    total_cost = 0
    total_quantity = 0

    product.product_inputs.each do |input|
      if input.unit_price.present? && input.quantity.present?
        total_cost += input.unit_price * input.quantity
        total_quantity += input.quantity
      end
    end

    return 0 if total_quantity.zero?
    total_cost / total_quantity
  end

  def calculate_daily_cash_flow
    # Fluxo de caixa diário (receitas - despesas por dia)
    @daily_cash_flow = {}

    (@start_date..@end_date).each do |date|
      daily_revenue = Sale.where(sale_date: date, status: 'pago').sum(:total_amount)
      daily_expenses = Expense.where(expense_date: date, status: 'ativa').sum(:amount)

      @daily_cash_flow[date] = {
        revenue: daily_revenue,
        expenses: daily_expenses,
        balance: daily_revenue - daily_expenses
      }
    end

    # Preparar dados para o gráfico
    @chart_labels = @daily_cash_flow.keys.map { |d| d.strftime('%d/%m') }
    @chart_revenue_data = @daily_cash_flow.values.map { |v| v[:revenue] }
    @chart_expenses_data = @daily_cash_flow.values.map { |v| v[:expenses] }
    @chart_balance_data = @daily_cash_flow.values.map { |v| v[:balance] }
  end

  def calculate_projections
    # Projeção de gastos para o mês
    # Baseada em despesas fixas mensais + média de despesas esporádicas dos últimos 3 meses

    # Despesas fixas mensais ativas
    @fixed_monthly = Expense.where(category: 'fixa_mensal', status: 'ativa').sum(:amount)

    # Média de despesas esporádicas dos últimos 3 meses
    three_months_ago = 3.months.ago.beginning_of_month
    sporadic_expenses = Expense.where(category: ['esporadica', 'rara'], status: 'ativa')
                               .where(expense_date: three_months_ago..Date.today)
                               .sum(:amount)

    @sporadic_average = sporadic_expenses / 3.0

    # Projeção total
    @projected_expenses = @fixed_monthly + @sporadic_average

    # Quanto já foi gasto este mês
    @spent_so_far = Expense.where(expense_date: @start_date..Date.today, status: 'ativa').sum(:amount)

    # Quanto ainda pode gastar
    @remaining_budget = @projected_expenses - @spent_so_far
  end

  def calculate_first_year
    # Busca o ano da primeira venda ou despesa registrada
    first_sale = Sale.order(:sale_date).first
    first_expense = Expense.order(:expense_date).first

    years = []
    years << first_sale.sale_date.year if first_sale
    years << first_expense.expense_date.year if first_expense

    # Se não houver registros, retorna o ano atual
    years.empty? ? Date.today.year : years.min
  end

  def calculate_top_products_and_services
    # TOP 10 PRODUTOS DO MÊS
    product_sales = {}

    @sales_this_month.each do |sale|
      sale.sale_products.each do |sp|
        next unless sp.product

        product_name = sp.product.name
        product_sales[product_name] ||= { quantity: 0, revenue: 0 }
        product_sales[product_name][:quantity] += sp.quantity
        product_sales[product_name][:revenue] += sp.unit_price * sp.quantity
      end
    end

    @top_products = product_sales.sort_by { |_, data| -data[:revenue] }.first(10)

    # TOP 10 SERVIÇOS DO MÊS
    service_sales = {}

    @sales_this_month.each do |sale|
      sale.sale_services.each do |ss|
        next unless ss.service

        service_name = ss.service.name
        service_sales[service_name] ||= { quantity: 0, revenue: 0 }
        service_sales[service_name][:quantity] += ss.quantity
        service_sales[service_name][:revenue] += ss.total_price
      end
    end

    @top_services = service_sales.sort_by { |_, data| -data[:revenue] }.first(10)
  end
end
