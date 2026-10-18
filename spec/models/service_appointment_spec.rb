# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServiceAppointment, type: :model do
  # ============================================
  # ASSOCIAÇÕES
  # ============================================
  describe 'associations' do
    it { is_expected.to belong_to(:service) }
    it { is_expected.to belong_to(:employee) }
    it { is_expected.to belong_to(:customer) }
  end

  # ============================================
  # VALIDAÇÕES
  # ============================================
  describe 'validations' do
    it { is_expected.to validate_presence_of(:service_id) }
    it { is_expected.to validate_presence_of(:employee_id) }
    it { is_expected.to validate_presence_of(:customer_id) }
    it { is_expected.to validate_presence_of(:appointment_date) }
    it { is_expected.to validate_presence_of(:duration_minutes) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_numericality_of(:duration_minutes).is_greater_than(0).is_less_than_or_equal_to(480) }

    describe 'appointment_date_cannot_be_in_the_past' do
      let(:employee) { create(:employee) }
      let(:customer) { create(:customer) }
      let(:service) { create(:service) }

      context 'when creating new appointment' do
        it 'rejects past dates' do
          appointment = build(:service_appointment,
                              employee: employee,
                              customer: customer,
                              service: service,
                              appointment_date: 1.day.ago)
          expect(appointment).not_to be_valid
          expect(appointment.errors[:appointment_date]).to include('não pode ser no passado')
        end

        it 'accepts future dates' do
          appointment = build(:service_appointment,
                              employee: employee,
                              customer: customer,
                              service: service,
                              appointment_date: 1.day.from_now.change(hour: 10))
          expect(appointment).to be_valid
        end
      end
    end

    describe 'appointment_time_must_be_within_business_hours' do
      let(:employee) { create(:employee) }
      let(:customer) { create(:customer) }
      let(:service) { create(:service) }

      it 'rejects appointments before 8:00' do
        appointment = build(:service_appointment,
                            employee: employee,
                            customer: customer,
                            service: service,
                            appointment_date: 1.day.from_now.change(hour: 7))
        expect(appointment).not_to be_valid
        expect(appointment.errors[:appointment_date]).to include('deve estar entre 08:00 e 23:59')
      end

      it 'accepts appointments at 8:00' do
        appointment = build(:service_appointment,
                            employee: employee,
                            customer: customer,
                            service: service,
                            appointment_date: 1.day.from_now.change(hour: 8))
        expect(appointment).to be_valid
      end

      it 'accepts appointments at 23:00' do
        appointment = build(:service_appointment,
                            employee: employee,
                            customer: customer,
                            service: service,
                            appointment_date: 1.day.from_now.change(hour: 23))
        expect(appointment).to be_valid
      end
    end

    describe 'no_conflicting_appointments' do
      let(:employee) { create(:employee) }
      let(:customer) { create(:customer) }
      let(:customer2) { create(:customer) }
      let(:service) { create(:service) }
      let(:appointment_time) { 2.days.from_now.change(hour: 10, min: 0) }

      before do
        create(:service_appointment,
               employee: employee,
               customer: customer,
               service: service,
               appointment_date: appointment_time,
               duration_minutes: 60)
      end

      it 'rejects overlapping appointments for same employee' do
        conflicting = build(:service_appointment,
                            employee: employee,
                            customer: customer2,
                            service: service,
                            appointment_date: appointment_time + 30.minutes,
                            duration_minutes: 60)
        expect(conflicting).not_to be_valid
        expect(conflicting.errors[:base].first).to match(/Conflito de horário/)
      end

      it 'accepts non-overlapping appointments for same employee' do
        non_conflicting = build(:service_appointment,
                                employee: employee,
                                customer: customer2,
                                service: service,
                                appointment_date: appointment_time + 90.minutes,
                                duration_minutes: 60)
        expect(non_conflicting).to be_valid
      end

      it 'accepts overlapping appointments for different employees' do
        other_employee = create(:employee)
        non_conflicting = build(:service_appointment,
                                employee: other_employee,
                                customer: customer2,
                                service: service,
                                appointment_date: appointment_time,
                                duration_minutes: 60)
        expect(non_conflicting).to be_valid
      end
    end
  end

  # ============================================
  # ENUMS
  # ============================================
  describe 'enums' do
    it 'has correct status values' do
      expected = %w[agendado concluido cancelado nao_compareceu]
      expect(ServiceAppointment.statuses.keys).to eq(expected)
    end
  end

  # ============================================
  # SCOPES
  # ============================================
  describe 'scopes' do
    let(:employee) { create(:employee) }
    let(:customer) { create(:customer) }
    let(:service) { create(:service) }

    describe '.upcoming' do
      let!(:future) do
        create(:service_appointment,
               employee: employee,
               customer: customer,
               service: service,
               appointment_date: 5.days.from_now.change(hour: 10))
      end

      let!(:past) do
        apt = create(:service_appointment,
                     employee: employee,
                     customer: customer,
                     service: service,
                     appointment_date: 1.day.from_now.change(hour: 10))
        # Force past date
        apt.update_column(:appointment_date, 1.day.ago)
        apt
      end

      it 'returns only future appointments' do
        expect(ServiceAppointment.upcoming).to include(future)
        expect(ServiceAppointment.upcoming).not_to include(past)
      end
    end

    describe '.past' do
      let!(:future) do
        create(:service_appointment,
               employee: employee,
               customer: customer,
               service: service,
               appointment_date: 5.days.from_now.change(hour: 10))
      end

      let!(:past) do
        apt = create(:service_appointment,
                     employee: employee,
                     customer: customer,
                     service: service,
                     appointment_date: 1.day.from_now.change(hour: 10))
        apt.update_column(:appointment_date, 1.day.ago)
        apt
      end

      it 'returns only past appointments' do
        expect(ServiceAppointment.past).to include(past)
        expect(ServiceAppointment.past).not_to include(future)
      end
    end

    describe '.by_service' do
      let(:service2) { create(:service) }
      let!(:apt1) do
        create(:service_appointment,
               employee: employee,
               customer: customer,
               service: service,
               appointment_date: 1.day.from_now.change(hour: 10))
      end
      let!(:apt2) do
        create(:service_appointment,
               employee: employee,
               customer: customer,
               service: service2,
               appointment_date: 1.day.from_now.change(hour: 14))
      end

      it 'filters by service' do
        expect(ServiceAppointment.by_service(service.id)).to include(apt1)
        expect(ServiceAppointment.by_service(service.id)).not_to include(apt2)
      end
    end

    describe '.by_employee' do
      let(:employee2) { create(:employee) }
      let!(:apt1) do
        create(:service_appointment,
               employee: employee,
               customer: customer,
               service: service,
               appointment_date: 1.day.from_now.change(hour: 10))
      end
      let!(:apt2) do
        create(:service_appointment,
               employee: employee2,
               customer: customer,
               service: service,
               appointment_date: 1.day.from_now.change(hour: 14))
      end

      it 'filters by employee' do
        expect(ServiceAppointment.by_employee(employee.id)).to include(apt1)
        expect(ServiceAppointment.by_employee(employee.id)).not_to include(apt2)
      end
    end

    describe '.active' do
      let!(:active) do
        create(:service_appointment,
               employee: employee,
               customer: customer,
               service: service,
               appointment_date: 1.day.from_now.change(hour: 10),
               status: :agendado)
      end
      let!(:cancelled) do
        create(:service_appointment,
               employee: employee,
               customer: customer,
               service: service,
               appointment_date: 1.day.from_now.change(hour: 14),
               status: :cancelado)
      end

      it 'excludes cancelled appointments' do
        expect(ServiceAppointment.active).to include(active)
        expect(ServiceAppointment.active).not_to include(cancelled)
      end
    end
  end

  # ============================================
  # MÉTODOS
  # ============================================
  describe '#overdue?' do
    let(:appointment) { build(:service_appointment) }

    context 'when past and agendado' do
      before do
        appointment.status = 'agendado'
        allow(appointment).to receive(:appointment_date).and_return(1.day.ago)
      end

      it 'returns true' do
        expect(appointment.overdue?).to be true
      end
    end

    context 'when past and concluido' do
      before do
        appointment.status = 'concluido'
        allow(appointment).to receive(:appointment_date).and_return(1.day.ago)
      end

      it 'returns false' do
        expect(appointment.overdue?).to be false
      end
    end

    context 'when future and agendado' do
      before do
        appointment.status = 'agendado'
        allow(appointment).to receive(:appointment_date).and_return(1.day.from_now)
      end

      it 'returns false' do
        expect(appointment.overdue?).to be false
      end
    end
  end

  describe '#status_badge_class' do
    it 'returns correct class for agendado' do
      appointment = build(:service_appointment, status: :agendado)
      expect(appointment.status_badge_class).to eq('bg-blue-100 text-blue-800')
    end

    it 'returns correct class for concluido' do
      appointment = build(:service_appointment, status: :concluido)
      expect(appointment.status_badge_class).to eq('bg-green-100 text-green-800')
    end

    it 'returns correct class for cancelado' do
      appointment = build(:service_appointment, status: :cancelado)
      expect(appointment.status_badge_class).to eq('bg-red-100 text-red-800')
    end

    it 'returns correct class for nao_compareceu' do
      appointment = build(:service_appointment, status: :nao_compareceu)
      expect(appointment.status_badge_class).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns default gray for unknown status' do
      appointment = build(:service_appointment, status: :agendado)
      allow(appointment).to receive(:status).and_return(nil)
      expect(appointment.status_badge_class).to eq('bg-gray-100 text-gray-800')
    end
  end

  describe '#appointment_time' do
    it 'returns the appointment_date' do
      time = 1.day.from_now.change(hour: 14, min: 30)
      appointment = build(:service_appointment, appointment_date: time)
      expect(appointment.appointment_time).to eq(time)
    end
  end

  describe '#formatted_time' do
    it 'formats appointment time' do
      appointment = build(:service_appointment, appointment_date: Time.zone.parse('2024-01-15 14:30'))
      expect(appointment.formatted_time).to eq('14:30')
    end

    it 'returns nil when appointment_date is nil' do
      appointment = build(:service_appointment, appointment_date: nil)
      expect(appointment.formatted_time).to be_nil
    end
  end

  describe '#end_time' do
    let(:appointment) do
      build(:service_appointment,
            appointment_date: Time.zone.parse('2024-01-15 10:00'),
            duration_minutes: 60)
    end

    it 'calculates end time correctly' do
      expect(appointment.end_time).to eq(Time.zone.parse('2024-01-15 11:00'))
    end

    context 'when appointment_date is nil' do
      let(:appointment) { build(:service_appointment, appointment_date: nil) }

      it 'returns nil' do
        expect(appointment.end_time).to be_nil
      end
    end

    context 'when duration_minutes is nil' do
      let(:appointment) { build(:service_appointment, duration_minutes: nil) }

      it 'returns nil' do
        expect(appointment.end_time).to be_nil
      end
    end
  end

  describe '#formatted_duration' do
    context 'when duration_minutes is nil' do
      it 'returns dash' do
        appointment = build(:service_appointment, duration_minutes: nil)
        expect(appointment.formatted_duration).to eq('-')
      end
    end

    context 'when less than 1 hour' do
      it 'shows only minutes' do
        appointment = build(:service_appointment, duration_minutes: 30)
        expect(appointment.formatted_duration).to eq('30 min')
      end
    end

    context 'when exactly 1 hour' do
      it 'shows 1 hora' do
        appointment = build(:service_appointment, duration_minutes: 60)
        expect(appointment.formatted_duration).to eq('1 hora')
      end
    end

    context 'when more than 1 hour without minutes' do
      it 'shows hours' do
        appointment = build(:service_appointment, duration_minutes: 120)
        expect(appointment.formatted_duration).to eq('2 horas')
      end
    end

    context 'when hours and minutes' do
      it 'shows both' do
        appointment = build(:service_appointment, duration_minutes: 90)
        expect(appointment.formatted_duration).to eq('1h 30min')
      end
    end
  end

  describe '#conflicts_with?' do
    let(:employee) { create(:employee) }
    let(:customer) { create(:customer) }
    let(:service) { create(:service) }
    let(:base_time) { 3.days.from_now.change(hour: 10, min: 0) }

    let!(:existing) do
      create(:service_appointment,
             employee: employee,
             customer: customer,
             service: service,
             appointment_date: base_time,
             duration_minutes: 60)
    end

    it 'returns true for overlapping appointment' do
      other = build(:service_appointment,
                    employee: employee,
                    appointment_date: base_time + 30.minutes,
                    duration_minutes: 60)
      expect(existing.conflicts_with?(other)).to be true
    end

    it 'returns false for non-overlapping appointment' do
      other = build(:service_appointment,
                    employee: employee,
                    appointment_date: base_time + 90.minutes,
                    duration_minutes: 60)
      expect(existing.conflicts_with?(other)).to be false
    end

    it 'returns false for same appointment' do
      expect(existing.conflicts_with?(existing)).to be false
    end

    it 'returns false for cancelled appointment' do
      other = build(:service_appointment,
                    employee: employee,
                    appointment_date: base_time,
                    duration_minutes: 60,
                    status: :cancelado)
      expect(existing.conflicts_with?(other)).to be false
    end

    it 'returns false for different employee' do
      other_employee = create(:employee)
      other = build(:service_appointment,
                    employee: other_employee,
                    appointment_date: base_time,
                    duration_minutes: 60)
      expect(existing.conflicts_with?(other)).to be false
    end
  end

  describe '.find_conflicts' do
    let(:employee) { create(:employee) }
    let(:customer) { create(:customer) }
    let(:service) { create(:service) }
    let(:base_time) { 4.days.from_now.change(hour: 10, min: 0) }

    let!(:existing) do
      create(:service_appointment,
             employee: employee,
             customer: customer,
             service: service,
             appointment_date: base_time,
             duration_minutes: 60)
    end

    it 'finds conflicting appointments' do
      conflicts = ServiceAppointment.find_conflicts(
        employee_id: employee.id,
        start_time: base_time + 30.minutes,
        duration_minutes: 60
      )
      expect(conflicts).to include(existing)
    end

    it 'excludes specified appointment' do
      conflicts = ServiceAppointment.find_conflicts(
        employee_id: employee.id,
        start_time: base_time,
        duration_minutes: 60,
        exclude_id: existing.id
      )
      expect(conflicts).to be_empty
    end

    it 'returns empty array when no employee_id' do
      conflicts = ServiceAppointment.find_conflicts(
        employee_id: nil,
        start_time: base_time,
        duration_minutes: 60
      )
      expect(conflicts).to be_empty
    end
  end

  describe '.slot_available?' do
    let(:employee) { create(:employee) }
    let(:customer) { create(:customer) }
    let(:service) { create(:service) }
    let(:base_time) { 5.days.from_now.change(hour: 10, min: 0) }

    before do
      create(:service_appointment,
             employee: employee,
             customer: customer,
             service: service,
             appointment_date: base_time,
             duration_minutes: 60)
    end

    it 'returns false for conflicting slot' do
      result = ServiceAppointment.slot_available?(
        employee_id: employee.id,
        start_time: base_time + 30.minutes,
        duration_minutes: 60
      )
      expect(result).to be false
    end

    it 'returns true for available slot' do
      result = ServiceAppointment.slot_available?(
        employee_id: employee.id,
        start_time: base_time + 90.minutes,
        duration_minutes: 60
      )
      expect(result).to be true
    end
  end

  # ============================================
  # CONSTANTES
  # ============================================
  describe 'DURATION_OPTIONS' do
    it 'contains expected options' do
      expect(ServiceAppointment::DURATION_OPTIONS).to include([ '15 minutos', 15 ])
      expect(ServiceAppointment::DURATION_OPTIONS).to include([ '1 hora', 60 ])
      expect(ServiceAppointment::DURATION_OPTIONS).to include([ '4 horas', 240 ])
    end
  end
end
