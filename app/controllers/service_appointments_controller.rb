class ServiceAppointmentsController < ApplicationController
  before_action :set_service_appointment, only: [ :show, :edit, :update, :destroy ]

  def search_services
    query = params[:query].to_s.strip
    @services = Service.where(active: "ativo")
                       .where("name ILIKE ?", "%#{query}%")
                       .order(:name)
                       .limit(10)

    render json: @services.map { |s| { id: s.id, name: s.name } }
  end

  def search_employees
    query = params[:query].to_s.strip
    @employees = Employee.where(status: "ativo")
                         .where("full_name ILIKE ?", "%#{query}%")
                         .order(:full_name)
                         .limit(10)

    render json: @employees.map { |e| { id: e.id, name: e.full_name } }
  end

  def search_customers
    query = params[:query].to_s.strip
    @customers = Customer.where("full_name ILIKE ?", "%#{query}%")
                         .order(:full_name)
                         .limit(10)

    render json: @customers.map { |c| { id: c.id, name: c.full_name } }
  end

  def index
    @service_appointments = ServiceAppointment.includes(:service, :employee, :customer).order(appointment_date: :desc)

    # Busca unificada
    if params[:search].present?
      search_term = params[:search].strip
      @service_appointments = @service_appointments.left_joins(:service, :employee, :customer)
                                                   .where("services.name ILIKE ? OR employees.full_name ILIKE ? OR customers.full_name ILIKE ?",
                                                          "%#{search_term}%", "%#{search_term}%", "%#{search_term}%")
                                                   .distinct
    end

    # Filtros individuais (mantidos para compatibilidade)
    @service_appointments = @service_appointments.by_service(params[:service_id]) if params[:service_id].present?
    @service_appointments = @service_appointments.by_customer(params[:customer_id]) if params[:customer_id].present?
    @service_appointments = @service_appointments.by_employee(params[:employee_id]) if params[:employee_id].present?
    @service_appointments = @service_appointments.by_date(params[:date]) if params[:date].present?
    @service_appointments = @service_appointments.by_status(params[:status]) if params[:status].present?

    @service_appointments = @service_appointments.page(params[:page]).per(15)
  end

  def show
  end

  def new
    @service_appointment = ServiceAppointment.new
  end

  def create
    @service_appointment = ServiceAppointment.new(service_appointment_params)

    if @service_appointment.save
      redirect_to @service_appointment, notice: "Agendamento criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service_appointment.update(service_appointment_params)
      redirect_to @service_appointment, notice: "Agendamento atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @service_appointment.destroy
      redirect_to service_appointments_url, notice: "Agendamento excluído com sucesso!"
    else
      redirect_to service_appointments_url, alert: "Erro ao excluir agendamento."
    end
  end

  private

  def set_service_appointment
    @service_appointment = ServiceAppointment.find(params[:id])
  end

  def service_appointment_params
    params.require(:service_appointment).permit(:service_id, :employee_id, :customer_id, :appointment_date, :status)
  end
end
