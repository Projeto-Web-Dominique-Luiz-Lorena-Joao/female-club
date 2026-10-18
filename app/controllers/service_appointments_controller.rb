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

  # Endpoint para verificar conflitos de horário via AJAX
  def check_conflicts
    employee_id = params[:employee_id]
    start_time = params[:start_time].present? ? Time.zone.parse(params[:start_time]) : nil
    duration_minutes = params[:duration_minutes].to_i
    exclude_id = params[:exclude_id]

    if employee_id.blank? || start_time.blank? || duration_minutes <= 0
      render json: { available: true, conflicts: [] }
      return
    end

    conflicts = ServiceAppointment.find_conflicts(
      employee_id: employee_id,
      start_time: start_time,
      duration_minutes: duration_minutes,
      exclude_id: exclude_id
    )

    if conflicts.any?
      conflict_data = conflicts.map do |apt|
        {
          id: apt.id,
          customer: apt.customer.full_name,
          service: apt.service.name,
          start_time: apt.appointment_date.strftime("%H:%M"),
          end_time: apt.end_time&.strftime("%H:%M"),
          duration: apt.formatted_duration
        }
      end

      render json: {
        available: false,
        conflicts: conflict_data,
        message: "Horário indisponível: #{conflicts.first.employee.full_name} já tem agendamento das #{conflicts.first.formatted_time} às #{conflicts.first.end_time&.strftime('%H:%M')}"
      }
    else
      render json: { available: true, conflicts: [] }
    end
  end

  def index
    @service_appointments = ServiceAppointment.includes(:service, :employee, :customer).order(appointment_date: :desc)

    # Busca unificada
    if params[:search].present?
      search_term = sanitize_search(params[:search])
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

    @service_appointments = @service_appointments.page(params[:page]).per(per_page)
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
    # PERFORMANCE: Eager loading para show/edit
    @service_appointment = ServiceAppointment.includes(:service, :employee, :customer).find(params[:id])
  end

  def service_appointment_params
    params.require(:service_appointment).permit(:service_id, :employee_id, :customer_id, :appointment_date, :status, :duration_minutes)
  end
end
