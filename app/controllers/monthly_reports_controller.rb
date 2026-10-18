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

    # Cache key baseado no mês e última atualização de vendas/despesas
    cache_key = monthly_report_cache_key

    # Usar cache para todo o cálculo de estatísticas
    cached_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      calculate_all_stats
    end

    # Atribuir dados do cache às variáveis de instância
    cached_data.each { |key, value| instance_variable_set("@#{key}", value) }
  end

  private

  def monthly_report_cache_key
    # Busca o timestamp da última atualização de vendas e despesas do mês
    last_sale_update = Sale.where(sale_date: @start_date..@end_date)
                           .maximum(:updated_at)&.to_i || 0
    last_expense_update = Expense.where(expense_date: @start_date..@end_date)
                                 .maximum(:updated_at)&.to_i || 0

    "monthly_report/#{@current_month.strftime('%Y-%m')}/#{last_sale_update}/#{last_expense_update}"
  end

  def calculate_all_stats
    calculate_monthly_stats
    calculate_daily_cash_flow
    calculate_projections
    calculate_top_products_and_services

    # Retorna hash com todas as variáveis de instância calculadas
    {
      sales_this_month: @sales_this_month,
      total_revenue: @total_revenue,
      total_expenses: @total_expenses,
      net_profit: @net_profit,
      received: @received,
      overdue_sales: @overdue_sales,
      overdue_amount: @overdue_amount,
      overdue_count: @overdue_count,
      pending_amount: @pending_amount,
      daily_cash_flow: @daily_cash_flow,
      cashflow_chart_labels: @cashflow_chart_labels,
      cashflow_chart_revenue: @cashflow_chart_revenue,
      cashflow_chart_expenses: @cashflow_chart_expenses,
      cashflow_chart_balance: @cashflow_chart_balance,
      comparison_chart_labels: @comparison_chart_labels,
      comparison_chart_data: @comparison_chart_data,
      fixed_monthly: @fixed_monthly,
      sporadic_average: @sporadic_average,
      projected_expenses: @projected_expenses,
      spent_so_far: @spent_so_far,
      remaining_budget: @remaining_budget,
      top_products: @top_products,
      top_services: @top_services
    }
  end

  def calculate_monthly_stats
    # Vendas do mês (apenas pagas ou pendentes, não canceladas)
    # Eager load para evitar N+1 queries
    @sales_this_month = Sale.where(sale_date: @start_date..@end_date)
                             .where.not(status: "cancelado")
                             .includes(sale_products: :product, sale_services: :service)

    # RECEITAS TOTAIS (soma de todas as vendas não canceladas)
    @total_revenue = @sales_this_month.sum(:total_amount)

    # DESPESAS TOTAIS (todas as despesas ativas, incluindo compra de produtos)
    @total_expenses = Expense.where(expense_date: @start_date..@end_date)
                             .where(status: "ativa")
                             .sum(:amount)

    # LUCRO LÍQUIDO
    # Fórmula simples: Receitas - Despesas
    # (As despesas já incluem a compra de produtos/supplies)
    @net_profit = @total_revenue - @total_expenses

    # RECEBIDO (vendas já pagas)
    @received = @sales_this_month.where(status: "pago").sum(:total_amount)

    # ATRASADOS (vendas pendentes do mês com data de vencimento passada)
    @overdue_sales = @sales_this_month.where(status: "pendente")
                                      .where("due_date < ?", Date.today)
    @overdue_amount = @overdue_sales.sum(:total_amount)
    @overdue_count = @overdue_sales.count

    # Vendas pendentes (a receber no futuro ou sem data definida)
    @pending_amount = @sales_this_month.where(status: "pendente")
                                       .where("due_date >= ? OR due_date IS NULL", Date.today)
                                       .sum(:total_amount)
  end

  def calculate_daily_cash_flow
    # Otimizado: Buscar todos os dados do mês com apenas 2 queries agregadas
    # Query 1: Vendas agrupadas por dia
    sales_by_day = Sale.where(sale_date: @start_date..@end_date)
                       .where.not(status: "cancelado")
                       .group(:sale_date)
                       .sum(:total_amount)

    # Query 2: Despesas agrupadas por dia
    expenses_by_day = Expense.where(expense_date: @start_date..@end_date, status: "ativa")
                             .group(:expense_date)
                             .sum(:amount)

    # Construir o hash de fluxo de caixa diário
    @daily_cash_flow = {}
    (@start_date..@end_date).each do |date|
      revenue = sales_by_day[date] || 0
      expenses = expenses_by_day[date] || 0

      @daily_cash_flow[date] = {
        revenue: revenue,
        expenses: expenses,
        balance: revenue - expenses
      }
    end

    # Preparar dados para o gráfico de Fluxo de Caixa Diário
    @cashflow_chart_labels = @daily_cash_flow.keys.map { |d| d.strftime("%d/%m") }
    @cashflow_chart_revenue = @daily_cash_flow.values.map { |v| v[:revenue] }
    @cashflow_chart_expenses = @daily_cash_flow.values.map { |v| v[:expenses] }
    @cashflow_chart_balance = @daily_cash_flow.values.map { |v| v[:balance] }

    # Preparar dados para o gráfico de Receitas vs Despesas (visão geral do mês)
    @comparison_chart_labels = [ "Receitas", "Despesas" ]
    @comparison_chart_data = [ @total_revenue, @total_expenses ]
  end

  def calculate_projections
    # Projeção de gastos para o mês
    # Baseada em despesas fixas mensais + média de despesas esporádicas dos últimos 3 meses

    # Média das despesas fixas mensais dos últimos 3 meses (para ter uma estimativa mais precisa)
    three_months_ago = 3.months.ago.beginning_of_month
    fixed_expenses_last_3_months = Expense.where(category: "fixa_mensal", status: "ativa")
                                          .where(expense_date: three_months_ago..Date.today)
                                          .sum(:amount)
    @fixed_monthly = fixed_expenses_last_3_months / 3.0

    # Média de despesas esporádicas dos últimos 3 meses
    sporadic_expenses = Expense.where(category: [ "esporadica", "rara" ], status: "ativa")
                               .where(expense_date: three_months_ago..Date.today)
                               .sum(:amount)

    @sporadic_average = sporadic_expenses / 3.0

    # Projeção total
    @projected_expenses = @fixed_monthly + @sporadic_average

    # Quanto já foi gasto este mês
    @spent_so_far = Expense.where(expense_date: @start_date..Date.today, status: "ativa").sum(:amount)

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
    # TOP 10 PRODUTOS DO MÊS - Otimizado com SQL agregado
    @top_products = SaleProduct.joins(:sale, :product)
                               .where(sales: { sale_date: @start_date..@end_date })
                               .where.not(sales: { status: "cancelado" })
                               .group("products.name")
                               .select("products.name as product_name,
                                        SUM(sale_products.quantity) as total_quantity,
                                        SUM(sale_products.unit_price * sale_products.quantity) as total_revenue")
                               .order("total_revenue DESC")
                               .limit(10)
                               .map { |sp| [ sp.product_name, { quantity: sp.total_quantity.to_i, revenue: sp.total_revenue.to_f } ] }

    # TOP 10 SERVIÇOS DO MÊS - Otimizado com SQL agregado
    @top_services = SaleService.joins(:sale, :service)
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
end
