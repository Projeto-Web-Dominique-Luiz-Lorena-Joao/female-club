class AppointmentsCalendarController < ApplicationController
  before_action :authenticate_user!

  def index
    # Determina o mês e ano baseado nos parâmetros ou usa o mês/ano atual
    @current_year = params[:year] ? params[:year].to_i : Date.today.year
    @current_month = params[:month] ? params[:month].to_i : Date.today.month

    @current_date = Date.new(@current_year, @current_month, 1)
    @start_date = @current_date.beginning_of_month
    @end_date = @current_date.end_of_month

    # Calcula o ano inicial baseado no primeiro registro
    @first_year = calculate_first_year
    @available_years = (@first_year..Date.today.year).to_a

    # Buscar todos os agendamentos do mês com eager loading
    # appointment_date é datetime, então precisamos buscar do início até o fim do mês
    start_datetime = @start_date.beginning_of_day
    end_datetime = @end_date.end_of_day

    @appointments = ServiceAppointment.where(appointment_date: start_datetime..end_datetime)
                                      .includes(:customer, :service, :employee)
                                      .order(:appointment_date)

    # Agrupar agendamentos por dia para facilitar a renderização no calendário
    @appointments_by_day = @appointments.group_by { |a| a.appointment_date.to_date.day }

    # Pegar dados do calendário brasileiro via API (feriados)
    @brazilian_holidays = fetch_brazilian_holidays(@current_year)
  end

  private

  def calculate_first_year
    first_appointment = ServiceAppointment.order(:appointment_date).first
    first_appointment ? first_appointment.appointment_date.year : Date.today.year
  end

  def fetch_brazilian_holidays(year)
    # Usando a API gratuita do Brasil API para pegar feriados nacionais
    # https://brasilapi.com.br/api/feriados/v1/{year}
    require "net/http"
    require "json"

    begin
      uri = URI("https://brasilapi.com.br/api/feriados/v1/#{year}")
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        holidays = JSON.parse(response.body)
        # Retorna um hash com a data como chave e o nome do feriado como valor
        holidays.each_with_object({}) do |holiday, hash|
          date = Date.parse(holiday["date"])
          hash[date] = holiday["name"] if date.month == @current_month
        end
      else
        {}
      end
    rescue => e
      Rails.logger.error("Erro ao buscar feriados: #{e.message}")
      {}
    end
  end
end
