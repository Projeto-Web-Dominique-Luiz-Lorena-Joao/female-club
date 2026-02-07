class ServiceAppointment < ApplicationRecord
  belongs_to :service
  belongs_to :employee
  belongs_to :customer

  enum :status, {
    agendado: "agendado",
    concluido: "concluido",
    cancelado: "cancelado",
    nao_compareceu: "nao_compareceu"
  }

  # Opções de duração em minutos
  DURATION_OPTIONS = [
    [ "15 minutos", 15 ],
    [ "30 minutos", 30 ],
    [ "45 minutos", 45 ],
    [ "1 hora", 60 ],
    [ "1 hora e 15 min", 75 ],
    [ "1 hora e 30 min", 90 ],
    [ "1 hora e 45 min", 105 ],
    [ "2 horas", 120 ],
    [ "2 horas e 30 min", 150 ],
    [ "3 horas", 180 ],
    [ "3 horas e 30 min", 210 ],
    [ "4 horas", 240 ]
  ].freeze

  validates :service_id, presence: true
  validates :employee_id, presence: true
  validates :customer_id, presence: true
  validates :appointment_date, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 480 }
  validate :appointment_date_cannot_be_in_the_past
  validate :appointment_time_must_be_within_business_hours
  validate :no_conflicting_appointments
  validates :status, presence: true, inclusion: { in: %w[agendado concluido cancelado nao_compareceu] }

  scope :upcoming, -> { where("appointment_date > ?", Time.current).order(:appointment_date) }
  scope :past, -> { where("appointment_date <= ?", Time.current).order(appointment_date: :desc) }
  scope :by_service, ->(service_id) { where(service_id: service_id) }
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_date, ->(date) { where("DATE(appointment_date) = ?", date) }
  scope :by_status, ->(status) { where(status: status) }
  scope :active, -> { where.not(status: "cancelado") }

  def overdue?
    appointment_date < Time.current && agendado?
  end

  def status_badge_class
    case status
    when "agendado"
      "bg-blue-100 text-blue-800"
    when "concluido"
      "bg-green-100 text-green-800"
    when "cancelado"
      "bg-red-100 text-red-800"
    when "nao_compareceu"
      "bg-yellow-100 text-yellow-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def formatted_time
    appointment_date&.strftime("%H:%M")
  end

  def appointment_time
    appointment_date
  end

  # Calcula o horário de término do agendamento
  def end_time
    return nil unless appointment_date.present? && duration_minutes.present?
    appointment_date + duration_minutes.minutes
  end

  # Retorna a duração formatada para exibição
  def formatted_duration
    return "-" unless duration_minutes.present?

    hours = duration_minutes / 60
    mins = duration_minutes % 60

    if hours.zero?
      "#{mins} min"
    elsif mins.zero?
      hours == 1 ? "1 hora" : "#{hours} horas"
    else
      "#{hours}h #{mins}min"
    end
  end

  # Verifica se há conflito com outro agendamento
  def conflicts_with?(other)
    return false if other.id == id
    return false if other.status == "cancelado"
    return false unless employee_id == other.employee_id

    my_start = appointment_date
    my_end = end_time
    other_start = other.appointment_date
    other_end = other.end_time

    return false unless my_start && my_end && other_start && other_end

    # Verifica sobreposição de horários
    (my_start < other_end) && (my_end > other_start)
  end

  # Busca agendamentos conflitantes para um funcionário em uma data/hora específica
  def self.find_conflicts(employee_id:, start_time:, duration_minutes:, exclude_id: nil)
    return [] unless employee_id.present? && start_time.present? && duration_minutes.present?

    end_time = start_time + duration_minutes.minutes

    # Busca agendamentos do mesmo funcionário no mesmo dia
    appointments = active
      .where(employee_id: employee_id)
      .where("DATE(appointment_date) = ?", start_time.to_date)

    appointments = appointments.where.not(id: exclude_id) if exclude_id.present?

    appointments.select do |apt|
      apt_end = apt.end_time
      next false unless apt_end

      # Verifica sobreposição
      (start_time < apt_end) && (end_time > apt.appointment_date)
    end
  end

  # Verifica se um horário está disponível para um funcionário
  def self.slot_available?(employee_id:, start_time:, duration_minutes:, exclude_id: nil)
    find_conflicts(
      employee_id: employee_id,
      start_time: start_time,
      duration_minutes: duration_minutes,
      exclude_id: exclude_id
    ).empty?
  end

  private

  def appointment_date_cannot_be_in_the_past
    # Só valida se for novo registro ou se a data foi alterada
    return unless new_record? || appointment_date_changed?

    if appointment_date.present? && appointment_date <= Time.current
      errors.add(:appointment_date, "não pode ser no passado")
    end
  end

  def appointment_time_must_be_within_business_hours
    # Só valida se for novo registro ou se a data foi alterada
    return unless new_record? || appointment_date_changed?

    if appointment_date.present?
      hour = appointment_date.hour
      if hour < 8 || hour >= 24
        errors.add(:appointment_date, "deve estar entre 08:00 e 23:59")
      end
    end
  end

  def no_conflicting_appointments
    # Só valida se for novo registro ou se a data/funcionário/duração foi alterada
    return unless new_record? || appointment_date_changed? || employee_id_changed? || duration_minutes_changed?
    return unless appointment_date.present? && employee_id.present? && duration_minutes.present?
    # Não valida conflitos para agendamentos cancelados
    return if status == "cancelado"

    conflicts = self.class.find_conflicts(
      employee_id: employee_id,
      start_time: appointment_date,
      duration_minutes: duration_minutes,
      exclude_id: id
    )

    if conflicts.any?
      conflict = conflicts.first
      errors.add(:base, "Conflito de horário: #{conflict.employee.full_name} já tem agendamento das #{conflict.formatted_time} às #{conflict.end_time&.strftime('%H:%M')} com #{conflict.customer.full_name}")
    end
  end
end
