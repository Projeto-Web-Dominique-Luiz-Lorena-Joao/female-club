require "test_helper"

class ServiceAppointmentTest < ActiveSupport::TestCase
  self.use_transactional_tests = true

  def setup
    @employee = Employee.find_or_create_by!(full_name: 'Test Employee', cpf: '12345678901', position: 'cabeleireira', phone: '1234567890')
    @customer = Customer.find_or_create_by!(full_name: 'Test Customer', cpf: '98765432100')
    @service = Service.create!(name: 'Corte de Cabelo', price: 50, active: 'ativo')
  end

  test "should create service_appointment with valid attributes" do
    appointment = ServiceAppointment.create!(
      service: @service,
      employee: @employee,
      customer: @customer,
      appointment_date: 2.days.from_now.change(hour: 10, minute: 0),
      status: "agendado"
    )

    assert appointment.persisted?
    assert_equal "agendado", appointment.status
    assert_equal @service.id, appointment.service_id
    assert_equal @employee.id, appointment.employee_id
    assert_equal @customer.id, appointment.customer_id
  end

  test "should require appointment_date" do
    appointment = ServiceAppointment.build(
      service: @service,
      employee: @employee,
      customer: @customer,
      appointment_date: nil,
      status: "agendado"
    )

    assert_not appointment.valid?
    assert appointment.errors[:appointment_date].present?
  end

  test "should require status" do
    appointment = ServiceAppointment.build(
      service: @service,
      employee: @employee,
      customer: @customer,
      appointment_date: 2.days.from_now.change(hour: 10, minute: 0),
      status: nil
    )

    assert_not appointment.valid?
    assert appointment.errors[:status].present?
  end
end
