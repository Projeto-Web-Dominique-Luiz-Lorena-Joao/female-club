class DailyReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Determina a data baseada nos parâmetros ou usa hoje
    @current_date = params[:date] ? Date.parse(params[:date]) : Date.today

    calculate_daily_stats
    calculate_hourly_stats if @current_date == Date.today
  end

  private

  def calculate_daily_stats
    # Vendas do dia (apenas pagas ou pendentes, não canceladas)
    @sales_today = Sale.where(sale_date: @current_date)
                       .where.not(status: "cancelado")

    # RECEITAS DO DIA
    @total_revenue = @sales_today.sum(:total_amount)

    # RECEBIDO HOJE (vendas já pagas)
    @received_today = @sales_today.where(status: "pago").sum(:total_amount)

    # PENDENTE HOJE
    @pending_today = @sales_today.where(status: "pendente").sum(:total_amount)

    # DESPESAS DO DIA (incluindo compra de produtos)
    @total_expenses = Expense.where(expense_date: @current_date, status: "ativa").sum(:amount)

    # SALDO DO DIA
    @daily_balance = @received_today - @total_expenses

    # LUCRO LÍQUIDO DO DIA
    # Fórmula simples: Receitas - Despesas
    # (As despesas já incluem a compra de produtos/supplies)
    @net_profit = @total_revenue - @total_expenses

    # QUANTIDADE DE VENDAS
    @sales_count = @sales_today.count

    # TICKET MÉDIO
    @average_ticket = @sales_count.positive? ? @total_revenue / @sales_count : 0

    # TOP PRODUTOS DO DIA
    @top_products = calculate_top_products

    # TOP SERVIÇOS DO DIA
    @top_services = calculate_top_services

    # ATRASADOS QUE VENCEM HOJE
    @due_today = Sale.where(due_date: @current_date, status: "pendente").sum(:total_amount)
    @due_today_count = Sale.where(due_date: @current_date, status: "pendente").count

    # AGENDAMENTOS DO DIA
    @appointments_today = ServiceAppointment.where(
      "DATE(appointment_date) = ?", @current_date
    ).count
  end

  def calculate_top_products
    product_sales = {}

    @sales_today.each do |sale|
      sale.sale_products.each do |sp|
        next unless sp.product

        product_name = sp.product.name
        product_sales[product_name] ||= { quantity: 0, revenue: 0 }
        product_sales[product_name][:quantity] += sp.quantity
        product_sales[product_name][:revenue] += sp.unit_price * sp.quantity
      end
    end

    product_sales.sort_by { |_, data| -data[:revenue] }.first(5)
  end

  def calculate_top_services
    service_sales = {}

    @sales_today.each do |sale|
      sale.sale_services.each do |ss|
        next unless ss.service

        service_name = ss.service.name
        service_sales[service_name] ||= { quantity: 0, revenue: 0 }
        service_sales[service_name][:quantity] += ss.quantity
        service_sales[service_name][:revenue] += ss.total_price
      end
    end

    service_sales.sort_by { |_, data| -data[:revenue] }.first(5)
  end

  def calculate_hourly_stats
    # Somente para o dia atual - distribuição por hora
    @hourly_sales = (0..23).map do |hour|
      hour_start = @current_date.to_time + hour.hours
      hour_end = hour_start + 1.hour

      sales_in_hour = Sale.where(created_at: hour_start...hour_end)
                          .where.not(status: "cancelado")
                          .sum(:total_amount)

      [ hour, sales_in_hour ]
    end
  end
end
