class ServiceAppointment < ApplicationRecord
  belongs_to :service
  belongs_to :employee
  belongs_to :customer

  enum :status, {
    agendado: 'agendado',
    concluido: 'concluido',
    cancelado: 'cancelado',
    nao_compareceu: 'nao_compareceu'
  }

  validates :service_id, presence: true
  validates :employee_id, presence: true
  validates :customer_id, presence: true
  validates :appointment_date, presence: true, comparison: { greater_than: :now, message: "não pode ser no passado" }
  validates :status, presence: true, inclusion: { in: %w[agendado concluido cancelado nao_compareceu] }

  scope :upcoming, -> { where('appointment_date > ?', Time.current).order(:appointment_date) }
  scope :past, -> { where('appointment_date <= ?', Time.current).order(appointment_date: :desc) }
  scope :by_service, ->(service_id) { where(service_id: service_id) }
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_date, ->(date) { where('DATE(appointment_date) = ?', date) }

  def overdue?
    appointment_date < Time.current && agendado?
  end

  def status_badge_class
    case status
    when 'agendado'
      'bg-blue-100 text-blue-800'
    when 'concluido'
      'bg-green-100 text-green-800'
    when 'cancelado'
      'bg-red-100 text-red-800'
    when 'nao_compareceu'
      'bg-yellow-100 text-yellow-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end
end
