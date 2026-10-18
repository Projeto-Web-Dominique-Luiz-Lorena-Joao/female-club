# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Service Appointments', type: :system do
  let(:user) { create(:user) }
  let(:customer) { create(:customer, full_name: 'Cliente Agendamento') }
  let(:employee) { create(:employee, full_name: 'Profissional Maria', status: 'ativo') }
  let(:service) { create(:service, name: 'Corte Premium', active: 'ativo') }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the appointments list page' do
      visit service_appointments_path

      expect(page).to have_content('Agendamentos')
    end

    context 'with appointments' do
      before do
        create(:service_appointment,
               customer: customer,
               employee: employee,
               service: service,
               appointment_date: 2.days.from_now.change(hour: 10),
               status: 'agendado')
      end

      it 'displays appointments' do
        visit service_appointments_path

        expect(page).to have_content('Cliente Agendamento')
        expect(page).to have_content('Profissional Maria')
        expect(page).to have_content('Corte Premium')
      end

      it 'filters by status' do
        visit service_appointments_path(status: 'agendado')

        expect(page).to have_content('Cliente Agendamento')
      end

      it 'filters by employee' do
        visit service_appointments_path(employee_id: employee.id)

        expect(page).to have_content('Cliente Agendamento')
      end
    end
  end

  describe 'Show page' do
    let(:appointment) do
      create(:service_appointment,
             customer: customer,
             employee: employee,
             service: service,
             appointment_date: 2.days.from_now.change(hour: 14),
             status: 'agendado')
    end

    it 'displays appointment details' do
      visit service_appointment_path(appointment)

      expect(page).to have_content('Cliente Agendamento')
      expect(page).to have_content('Profissional Maria')
      expect(page).to have_content('Corte Premium')
    end

    it 'has edit and back links' do
      visit service_appointment_path(appointment)

      expect(page).to have_link('Editar')
      expect(page).to have_link('Voltar')
    end
  end

  describe 'New appointment' do
    before do
      customer
      employee
      service
    end

    it 'displays the new appointment form' do
      visit new_service_appointment_path

      expect(page).to have_content('Novo Agendamento')
      expect(page).to have_css('#appointment_date_field')
      expect(page).to have_css('#duration_minutes_field')
    end
  end

  describe 'Edit appointment' do
    let(:appointment) do
      create(:service_appointment,
             customer: customer,
             employee: employee,
             service: service,
             appointment_date: 2.days.from_now.change(hour: 10),
             status: 'agendado')
    end

    it 'displays the edit form' do
      visit edit_service_appointment_path(appointment)

      expect(page).to have_css('#appointment_date_field')
    end

    it 'updates appointment status' do
      visit edit_service_appointment_path(appointment)

      select 'Concluído', from: 'Status'
      click_button 'Salvar Agendamento'

      expect(page).to have_content('Agendamento atualizado com sucesso')
    end
  end
end
