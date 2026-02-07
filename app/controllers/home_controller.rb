class HomeController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # PERFORMANCE: Atualização otimizada de status de estoque via SQL
    update_stock_status_batch

    # Período do mês atual (usado em seções específicas)
    @current_month_start = Date.current.beginning_of_month
    @current_month_end = Date.current.end_of_month
    @last_month_start = 1.month.ago.beginning_of_month
    @last_month_end = 1.month.ago.end_of_month

    # Período anual (usado nos KPIs da visão geral)
    @current_year_start = Date.current.beginning_of_year
    @current_year_end = Date.current.end_of_year
    @last_year_start = 1.year.ago.beginning_of_year
    @last_year_end = 1.year.ago.end_of_year

    # KPIs com dados reais
    calculate_kpis

    # Dados do gráfico de vendas (últimos 8 meses)
    calculate_sales_chart_data

    # Produtos mais vendidos do mês
    calculate_top_products

    # Agendamentos
    calculate_appointments

    # Despesas do mês
    calculate_expenses

    # Vendas recentes
    calculate_recent_sales
  end

  private

  def calculate_kpis
    # Vendas do ano atual (não canceladas)
    vendas_ano_atual = Sale.where(sale_date: @current_year_start..@current_year_end)
                           .where.not(status: "cancelado")
    @vendas_ano = vendas_ano_atual.sum(:total_amount)
    @total_vendas = vendas_ano_atual.count

    # Vendas do ano anterior para comparação
    vendas_ano_anterior = Sale.where(sale_date: @last_year_start..@last_year_end)
                              .where.not(status: "cancelado")
    @vendas_ano_anterior = vendas_ano_anterior.sum(:total_amount)
    @total_vendas_anterior = vendas_ano_anterior.count

    # Calcular variação percentual
    @variacao_vendas = calculate_variation(@vendas_ano, @vendas_ano_anterior)
    @variacao_total = calculate_variation(@total_vendas, @total_vendas_anterior)

    # Clientes ativos (com compra no ano atual)
    @clientes_ativos = Customer.joins(:sales)
                               .where(sales: { sale_date: @current_year_start..@current_year_end })
                               .where.not(sales: { status: "cancelado" })
                               .distinct
                               .count

    clientes_ativos_anterior = Customer.joins(:sales)
                                       .where(sales: { sale_date: @last_year_start..@last_year_end })
                                       .where.not(sales: { status: "cancelado" })
                                       .distinct
                                       .count
    @variacao_clientes = calculate_variation(@clientes_ativos, clientes_ativos_anterior)

    # Estoque baixo
    @estoque_baixo = Product.where(stock_status: [ "baixo", "critico" ]).count

    # Despesas do ano
    @despesas_ano = Expense.where(expense_date: @current_year_start..@current_year_end)
                           .where(status: "ativa")
                           .sum(:amount)
    despesas_ano_anterior = Expense.where(expense_date: @last_year_start..@last_year_end)
                                   .where(status: "ativa")
                                   .sum(:amount)
    @variacao_despesas = calculate_variation(@despesas_ano, despesas_ano_anterior)

    # Lucro estimado anual (vendas - despesas)
    @lucro_ano = @vendas_ano - @despesas_ano

    # Agendamentos de hoje
    @agendamentos_hoje = ServiceAppointment.where(
      appointment_date: Date.current.beginning_of_day..Date.current.end_of_day
    ).where.not(status: "cancelado").count

    # Vendas pendentes (não pagas)
    @vendas_pendentes = Sale.where(status: "pendente").count
  end

  def calculate_sales_chart_data
    # Últimos 8 meses de vendas
    @chart_labels = []
    @vendas_data = []
    @despesas_data = []

    8.downto(1) do |i|
      month_date = (i - 1).months.ago
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      @chart_labels << I18n.l(month_start, format: "%b")

      total_vendas = Sale.where(sale_date: month_start..month_end)
                         .where.not(status: "cancelado")
                         .sum(:total_amount)
      @vendas_data << total_vendas.to_f

      total_despesas = Expense.where(expense_date: month_start..month_end)
                              .where(status: "ativa")
                              .sum(:amount)
      @despesas_data << total_despesas.to_f
    end
  end

  def calculate_top_products
    # Top 5 produtos mais vendidos no ano atual
    product_sales = {}

    Sale.where(sale_date: @current_year_start..@current_year_end)
        .where.not(status: "cancelado")
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

  def calculate_appointments
    today = Date.current

    # Próximos agendamentos (hoje e futuros, não cancelados)
    @proximos_agendamentos = ServiceAppointment
      .includes(:service, :employee, :customer)
      .where("appointment_date >= ?", today.beginning_of_day)
      .where.not(status: "cancelado")
      .order(appointment_date: :asc)
      .limit(5)

    # Resumo de agendamentos do ano
    agendamentos_ano = ServiceAppointment.where(
      appointment_date: @current_year_start.beginning_of_day..@current_year_end.end_of_day
    )
    @agendamentos_total_ano = agendamentos_ano.count
    @agendamentos_concluidos = agendamentos_ano.where(status: "concluido").count
    @agendamentos_cancelados = agendamentos_ano.where(status: "cancelado").count
    @agendamentos_pendentes = agendamentos_ano.where(status: "agendado").count
  end

  def calculate_expenses
    # Top despesas por tipo no ano
    @despesas_por_tipo = Expense.where(expense_date: @current_year_start..@current_year_end)
                                .where(status: "ativa")
                                .group(:expense_type)
                                .sum(:amount)
                                .sort_by { |_, v| -v }
                                .first(5)
  end

  def calculate_recent_sales
    @vendas_recentes = Sale.includes(:customer, :employee)
                           .where.not(status: "cancelado")
                           .order(sale_date: :desc, created_at: :desc)
                           .limit(5)
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
