# frozen_string_literal: true

require "test_helper"

class ServiceAppointmentTest < ActiveSupport::TestCase
  setup do
    @service = create(:service)
    @employee = create(:employee)
    @customer = create(:customer)
  end

  # Helper para gerar datetime no horário comercial (usando Time.zone)
  def business_time(days_from_now: 1, hour: 10, min: 0)
    Time.zone.now.beginning_of_day + days_from_now.days + hour.hours + min.minutes
  end

  # Helper para criar agendamento com associações padrão
  def build_appointment(**attrs)
    defaults = {
      service: @service,
      employee: @employee,
      customer: @customer
    }
    build(:service_appointment, **defaults.merge(attrs))
  end

  def create_appointment(**attrs)
    defaults = {
      service: @service,
      employee: @employee,
      customer: @customer
    }
    create(:service_appointment, **defaults.merge(attrs))
  end

  # Helper para verificar erro de conflito de horário
  def assert_has_conflict_error(appointment, message = nil)
    assert_not appointment.valid?, message || "Agendamento conflitante deveria ser inválido"
    has_conflict_error = appointment.errors[:base].any? { |e| e.include?("Conflito") } ||
                         appointment.errors[:appointment_date].any?
    assert has_conflict_error, message || "Deveria ter erro de conflito de horário"
  end

  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar agendamento com atributos válidos" do
    appointment = build_appointment
    assert_valid appointment
  end

  test "deve exigir serviço" do
    appointment = build(:service_appointment, service: nil)
    assert_invalid appointment, :service
  end

  test "deve exigir funcionário" do
    appointment = build(:service_appointment, employee: nil)
    assert_invalid appointment, :employee
  end

  test "deve exigir cliente" do
    appointment = build(:service_appointment, customer: nil)
    assert_invalid appointment, :customer
  end

  test "deve exigir data do agendamento" do
    appointment = build(:service_appointment, appointment_date: nil)
    assert_invalid appointment, :appointment_date
  end

  test "deve exigir status" do
    appointment = build(:service_appointment, status: nil)
    assert_invalid appointment, :status
  end

  test "deve exigir duração" do
    appointment = build(:service_appointment, duration_minutes: nil)
    assert_invalid appointment, :duration_minutes
  end

  # ============================================
  # VALIDAÇÃO DE DURAÇÃO
  # ============================================

  test "duração deve ser maior que zero" do
    appointment = build(:service_appointment, duration_minutes: 0)
    assert_invalid appointment, :duration_minutes
  end

  test "duração não pode ser negativa" do
    appointment = build(:service_appointment, duration_minutes: -30)
    assert_invalid appointment, :duration_minutes
  end

  test "duração máxima é 480 minutos (8 horas)" do
    appointment = build(:service_appointment, duration_minutes: 481)
    assert_invalid appointment, :duration_minutes
  end

  test "aceita duração de 480 minutos" do
    appointment = build_appointment(duration_minutes: 480)
    assert_valid appointment
  end

  test "aceita todas as durações padrão" do
    ServiceAppointment::DURATION_OPTIONS.each do |_label, minutes|
      appointment = build_appointment(
        duration_minutes: minutes,
        appointment_date: 1.day.from_now.change(hour: 10, min: 0))
      assert_valid appointment, "Duração de #{minutes} minutos deveria ser válida"
    end
  end

  # ============================================
  # VALIDAÇÃO DE HORÁRIO
  # ============================================

  test "não permite agendamento no passado" do
    appointment = build_appointment(appointment_date: 1.hour.ago)
    assert_invalid appointment, :appointment_date
  end

  test "não permite agendamento antes das 8h" do
    appointment = build_appointment(
      appointment_date: 1.day.from_now.change(hour: 7, min: 59))
    assert_invalid appointment, :appointment_date
  end

  test "permite agendamento às 8h" do
    appointment = build_appointment(
      appointment_date: 1.day.from_now.change(hour: 8, min: 0))
    assert_valid appointment
  end

  test "permite agendamento até 23:59" do
    appointment = build_appointment(
      appointment_date: 1.day.from_now.change(hour: 23, min: 0),
      duration_minutes: 59)
    assert_valid appointment
  end

  # ============================================
  # DETECÇÃO DE CONFLITOS - CASOS BÁSICOS
  # ============================================

  test "não permite dois agendamentos no mesmo horário para o mesmo funcionário" do
    employee = create(:employee)
    service = create(:service)
    customer = create(:customer)
    tomorrow_10am = 1.day.from_now.change(hour: 10, min: 0)

    create(:service_appointment,
           employee: employee,
           service: service,
           customer: customer,
           appointment_date: tomorrow_10am,
           duration_minutes: 60)

    conflicting = build(:service_appointment,
                        employee: employee,
                        service: service,
                        customer: create(:customer),
                        appointment_date: tomorrow_10am,
                        duration_minutes: 60)

    assert_not conflicting.valid?, "Agendamento conflitante deveria ser inválido"
    assert conflicting.errors[:base].any? || conflicting.errors[:appointment_date].any?,
           "Deveria ter erro de conflito de horário"
  end

  test "permite agendamentos no mesmo horário para funcionários diferentes" do
    employee1 = create(:employee)
    employee2 = create(:employee)
    service = create(:service)
    tomorrow_10am = 1.day.from_now.change(hour: 10, min: 0)

    create(:service_appointment,
           employee: employee1,
           service: service,
           customer: create(:customer),
           appointment_date: tomorrow_10am,
           duration_minutes: 60)

    second_appointment = build(:service_appointment,
                               employee: employee2,
                               service: service,
                               customer: create(:customer),
                               appointment_date: tomorrow_10am,
                               duration_minutes: 60)

    assert_valid second_appointment
  end

  # ============================================
  # DETECÇÃO DE CONFLITOS - SOBREPOSIÇÃO PARCIAL
  # ============================================

  test "detecta conflito quando novo agendamento começa durante outro" do
    create_appointment(
      appointment_date: business_time(hour: 10, min: 0),
      duration_minutes: 60)

    conflicting = build_appointment(
      customer: create(:customer),
      appointment_date: business_time(hour: 10, min: 30),
      duration_minutes: 60)

    assert_has_conflict_error conflicting
  end

  test "detecta conflito quando novo agendamento termina durante outro" do
    create_appointment(
      appointment_date: business_time(hour: 10, min: 0),
      duration_minutes: 60)

    conflicting = build_appointment(
      customer: create(:customer),
      appointment_date: business_time(hour: 9, min: 30),
      duration_minutes: 60)

    assert_has_conflict_error conflicting
  end

  test "detecta conflito quando novo agendamento engloba outro completamente" do
    create_appointment(
      appointment_date: business_time(hour: 10, min: 0),
      duration_minutes: 60)

    conflicting = build_appointment(
      customer: create(:customer),
      appointment_date: business_time(hour: 9, min: 0),
      duration_minutes: 180)

    assert_has_conflict_error conflicting
  end

  test "detecta conflito quando novo agendamento está contido em outro" do
    create_appointment(
      appointment_date: business_time(hour: 9, min: 0),
      duration_minutes: 180)

    conflicting = build_appointment(
      customer: create(:customer),
      appointment_date: business_time(hour: 10, min: 0),
      duration_minutes: 60)

    assert_has_conflict_error conflicting
  end

  # ============================================
  # DETECÇÃO DE CONFLITOS - CASOS DE BORDA
  # ============================================

  test "permite agendamento que começa exatamente quando outro termina" do
    create_appointment(
      appointment_date: business_time(hour: 10, min: 0),
      duration_minutes: 60)

    consecutive = build_appointment(
      customer: create(:customer),
      appointment_date: business_time(hour: 11, min: 0),
      duration_minutes: 60)

    assert_valid consecutive
  end

  test "permite agendamento que termina exatamente quando outro começa" do
    create_appointment(
      appointment_date: business_time(hour: 11, min: 0),
      duration_minutes: 60)

    consecutive = build_appointment(
      customer: create(:customer),
      appointment_date: business_time(hour: 10, min: 0),
      duration_minutes: 60)

    assert_valid consecutive
  end

  # ============================================
  # AGENDAMENTOS CANCELADOS NÃO GERAM CONFLITO
  # ============================================

  test "agendamento cancelado não gera conflito" do
    employee = create(:employee)
    service = create(:service)
    customer = create(:customer)
    tomorrow_10am = 1.day.from_now.change(hour: 10, min: 0)

    create(:service_appointment,
           employee: employee,
           service: service,
           customer: customer,
           appointment_date: tomorrow_10am,
           duration_minutes: 60,
           status: :cancelado)

    new_appointment = build(:service_appointment,
                            employee: employee,
                            service: service,
                            customer: create(:customer),
                            appointment_date: tomorrow_10am,
                            duration_minutes: 60)

    assert_valid new_appointment
  end

  # ============================================
  # EDIÇÃO DE AGENDAMENTO EXISTENTE
  # ============================================

  test "pode editar agendamento sem conflito consigo mesmo" do
    employee = create(:employee)
    tomorrow_10am = 1.day.from_now.change(hour: 10, min: 0)

    appointment = create(:service_appointment,
                         employee: employee,
                         appointment_date: tomorrow_10am,
                         duration_minutes: 60)

    appointment.duration_minutes = 90
    assert_valid appointment
  end

  test "pode alterar horário de agendamento existente para slot livre" do
    employee = create(:employee)

    appointment = create(:service_appointment,
                         employee: employee,
                         appointment_date: business_time(hour: 10, min: 0),
                         duration_minutes: 60)

    appointment.appointment_date = business_time(hour: 14, min: 0)
    assert_valid appointment
  end

  test "não pode mover agendamento para horário ocupado por outro" do
    create_appointment(
      appointment_date: business_time(hour: 14, min: 0),
      duration_minutes: 60)

    appointment = create_appointment(
      customer: create(:customer),
      appointment_date: business_time(hour: 10, min: 0),
      duration_minutes: 60)

    appointment.appointment_date = business_time(hour: 14, min: 0)
    assert_has_conflict_error appointment
  end

  # ============================================
  # MÉTODOS DE CLASSE
  # ============================================

  test "find_conflicts retorna agendamentos conflitantes" do
    employee = create(:employee)
    start_time = business_time(hour: 10, min: 0)

    conflicting = create(:service_appointment,
                         employee: employee,
                         appointment_date: start_time,
                         duration_minutes: 60)

    conflicts = ServiceAppointment.find_conflicts(
      employee_id: employee.id,
      start_time: start_time,
      duration_minutes: 60
    )

    assert_includes conflicts, conflicting
  end

  test "find_conflicts exclui agendamento especificado" do
    employee = create(:employee)
    start_time = business_time(hour: 10, min: 0)

    existing = create(:service_appointment,
                      employee: employee,
                      appointment_date: start_time,
                      duration_minutes: 60)

    conflicts = ServiceAppointment.find_conflicts(
      employee_id: employee.id,
      start_time: start_time,
      duration_minutes: 60,
      exclude_id: existing.id
    )

    assert_not_includes conflicts, existing
  end

  test "slot_available? retorna true quando slot está livre" do
    employee = create(:employee)
    start_time = business_time(hour: 10, min: 0)

    assert ServiceAppointment.slot_available?(
      employee_id: employee.id,
      start_time: start_time,
      duration_minutes: 60
    )
  end

  test "slot_available? retorna false quando há conflito" do
    employee = create(:employee)
    start_time = business_time(hour: 10, min: 0)

    create(:service_appointment,
           employee: employee,
           appointment_date: start_time,
           duration_minutes: 60)

    assert_not ServiceAppointment.slot_available?(
      employee_id: employee.id,
      start_time: start_time,
      duration_minutes: 60
    )
  end

  # ============================================
  # MÉTODOS DE INSTÂNCIA
  # ============================================

  test "end_time calcula corretamente o horário de término" do
    appointment = build(:service_appointment,
                        appointment_date: 1.day.from_now.change(hour: 10, min: 0),
                        duration_minutes: 90)

    expected_end = 1.day.from_now.change(hour: 11, min: 30)
    assert_equal expected_end.to_i, appointment.end_time.to_i
  end

  test "end_time retorna nil se appointment_date é nil" do
    appointment = build(:service_appointment, appointment_date: nil)
    assert_nil appointment.end_time
  end

  test "formatted_duration retorna formato legível para minutos" do
    appointment = build(:service_appointment, duration_minutes: 45)
    assert_equal "45 min", appointment.formatted_duration
  end

  test "formatted_duration retorna formato legível para horas exatas" do
    appointment = build(:service_appointment, duration_minutes: 120)
    assert_equal "2 horas", appointment.formatted_duration
  end

  test "formatted_duration retorna formato legível para horas e minutos" do
    appointment = build(:service_appointment, duration_minutes: 90)
    assert_equal "1h 30min", appointment.formatted_duration
  end

  test "conflicts_with? detecta conflito entre dois agendamentos" do
    employee = create(:employee)

    appointment1 = create(:service_appointment,
                          employee: employee,
                          appointment_date: business_time(hour: 10, min: 0),
                          duration_minutes: 60)

    appointment2 = build(:service_appointment,
                         employee: employee,
                         appointment_date: business_time(hour: 10, min: 30),
                         duration_minutes: 60)

    assert appointment1.conflicts_with?(appointment2)
    assert appointment2.conflicts_with?(appointment1)
  end

  test "conflicts_with? não detecta conflito entre agendamentos consecutivos" do
    employee = create(:employee)

    appointment1 = create(:service_appointment,
                          employee: employee,
                          appointment_date: business_time(hour: 10, min: 0),
                          duration_minutes: 60)

    appointment2 = create(:service_appointment,
                          employee: employee,
                          appointment_date: business_time(hour: 11, min: 0),
                          duration_minutes: 60)

    assert_not appointment1.conflicts_with?(appointment2)
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope active exclui agendamentos cancelados" do
    active = create(:service_appointment, status: :agendado)
    cancelled = create(:service_appointment, status: :cancelado)

    active_appointments = ServiceAppointment.active

    assert_includes active_appointments, active
    assert_not_includes active_appointments, cancelled
  end

  test "scope by_employee filtra por funcionário" do
    employee1 = create(:employee)
    employee2 = create(:employee)

    apt1 = create(:service_appointment, employee: employee1)
    apt2 = create(:service_appointment, employee: employee2)

    result = ServiceAppointment.by_employee(employee1.id)

    assert_includes result, apt1
    assert_not_includes result, apt2
  end

  test "scope by_date filtra por data" do
    date1 = 1.day.from_now.to_date
    date2 = 2.days.from_now.to_date

    apt1 = create(:service_appointment, appointment_date: business_time(hour: 10))
    apt2 = create(:service_appointment, appointment_date: business_time(days_from_now: 2, hour: 10))

    result = ServiceAppointment.by_date(date1)

    assert_includes result, apt1
    assert_not_includes result, apt2
  end

  # ============================================
  # ENUMS
  # ============================================

  test "status enum tem valores corretos" do
    assert_equal %w[agendado concluido cancelado nao_compareceu], ServiceAppointment.statuses.keys
  end

  test "pode alterar status para concluído" do
    appointment = create(:service_appointment, status: :agendado)
    appointment.concluido!
    assert appointment.concluido?
  end

  test "pode alterar status para cancelado" do
    appointment = create(:service_appointment, status: :agendado)
    appointment.cancelado!
    assert appointment.cancelado?
  end

  test "pode alterar status para nao_compareceu" do
    appointment = create(:service_appointment, status: :agendado)
    appointment.nao_compareceu!
    assert appointment.nao_compareceu?
  end

  # ============================================
  # MÉTODOS ADICIONAIS
  # ============================================

  test "overdue? retorna true para agendamento passado e ainda agendado" do
    # Criar agendamento no passado sem validação
    appointment = build(:service_appointment, status: :agendado)
    appointment.save(validate: false)
    appointment.update_column(:appointment_date, 1.day.ago)

    assert appointment.overdue?
  end

  test "overdue? retorna false para agendamento futuro" do
    appointment = create(:service_appointment, status: :agendado)
    assert_not appointment.overdue?
  end

  test "overdue? retorna false para agendamento concluído" do
    appointment = build(:service_appointment, status: :concluido)
    appointment.save(validate: false)
    appointment.update_column(:appointment_date, 1.day.ago)

    assert_not appointment.overdue?
  end

  test "status_badge_class para agendado" do
    appointment = build(:service_appointment, status: :agendado)
    assert_equal "bg-blue-100 text-blue-800", appointment.status_badge_class
  end

  test "status_badge_class para concluido" do
    appointment = build(:service_appointment, status: :concluido)
    assert_equal "bg-green-100 text-green-800", appointment.status_badge_class
  end

  test "status_badge_class para cancelado" do
    appointment = build(:service_appointment, status: :cancelado)
    assert_equal "bg-red-100 text-red-800", appointment.status_badge_class
  end

  test "status_badge_class para nao_compareceu" do
    appointment = build(:service_appointment, status: :nao_compareceu)
    assert_equal "bg-yellow-100 text-yellow-800", appointment.status_badge_class
  end

  test "formatted_time retorna horário formatado" do
    appointment = build(:service_appointment, appointment_date: Time.zone.parse("2026-01-25 14:30"))
    assert_equal "14:30", appointment.formatted_time
  end

  test "formatted_time retorna nil se appointment_date é nil" do
    appointment = build(:service_appointment, appointment_date: nil)
    assert_nil appointment.formatted_time
  end

  test "appointment_time retorna appointment_date" do
    date = 1.day.from_now.change(hour: 10)
    appointment = build(:service_appointment, appointment_date: date)
    assert_equal date.to_i, appointment.appointment_time.to_i
  end

  test "formatted_duration retorna traço se duration_minutes é nil" do
    appointment = build(:service_appointment, duration_minutes: nil)
    assert_equal "-", appointment.formatted_duration
  end

  test "formatted_duration para 1 hora exata" do
    appointment = build(:service_appointment, duration_minutes: 60)
    assert_equal "1 hora", appointment.formatted_duration
  end

  test "conflicts_with? retorna false para mesmo agendamento" do
    appointment = create(:service_appointment)
    assert_not appointment.conflicts_with?(appointment)
  end

  test "conflicts_with? retorna false para agendamento cancelado" do
    employee = create(:employee)

    appointment1 = create(:service_appointment,
                          employee: employee,
                          appointment_date: business_time(hour: 10),
                          status: :cancelado)

    appointment2 = build(:service_appointment,
                         employee: employee,
                         appointment_date: business_time(hour: 10))

    assert_not appointment2.conflicts_with?(appointment1)
  end

  test "conflicts_with? retorna false para funcionários diferentes" do
    employee1 = create(:employee)
    employee2 = create(:employee)

    appointment1 = create(:service_appointment,
                          employee: employee1,
                          appointment_date: business_time(hour: 10))

    appointment2 = build(:service_appointment,
                         employee: employee2,
                         appointment_date: business_time(hour: 10))

    assert_not appointment1.conflicts_with?(appointment2)
  end

  test "find_conflicts retorna array vazio com parâmetros inválidos" do
    assert_equal [], ServiceAppointment.find_conflicts(employee_id: nil, start_time: nil, duration_minutes: nil)
  end

  test "scope upcoming retorna apenas agendamentos futuros" do
    future = create(:service_appointment, appointment_date: 1.day.from_now.change(hour: 10))

    result = ServiceAppointment.upcoming

    assert_includes result, future
  end

  test "scope by_service filtra por serviço" do
    service1 = create(:service)
    service2 = create(:service)

    apt1 = create(:service_appointment, service: service1)
    apt2 = create(:service_appointment, service: service2)

    result = ServiceAppointment.by_service(service1.id)

    assert_includes result, apt1
    assert_not_includes result, apt2
  end

  test "scope by_customer filtra por cliente" do
    customer1 = create(:customer)
    customer2 = create(:customer)

    apt1 = create(:service_appointment, customer: customer1)
    apt2 = create(:service_appointment, customer: customer2)

    result = ServiceAppointment.by_customer(customer1.id)

    assert_includes result, apt1
    assert_not_includes result, apt2
  end

  test "scope by_status filtra por status" do
    agendado = create(:service_appointment, status: :agendado)
    concluido = create(:service_appointment, status: :concluido)

    result = ServiceAppointment.by_status(:agendado)

    assert_includes result, agendado
    assert_not_includes result, concluido
  end
end
