# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ServiceAppointments', type: :request do
  let(:user) { create(:user) }
  let(:customer) { create(:customer) }
  let(:employee) { create(:employee, status: 'ativo') }
  let(:service) { create(:service, active: 'ativo') }

  before { login_as(user, scope: :user) }

  describe 'GET /service_appointments' do
    before do
      create_list(:service_appointment, 3, customer: customer, employee: employee, service: service)
    end

    it 'returns success' do
      get service_appointments_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the appointments list' do
      get service_appointments_path
      expect(response.body).to include('Agendamento')
    end

    context 'with search' do
      it 'searches by service, employee, or customer name' do
        get service_appointments_path, params: { search: customer.full_name }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with service_id filter' do
      it 'filters by service' do
        get service_appointments_path, params: { service_id: service.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with customer_id filter' do
      it 'filters by customer' do
        get service_appointments_path, params: { customer_id: customer.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with employee_id filter' do
      it 'filters by employee' do
        get service_appointments_path, params: { employee_id: employee.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with date filter' do
      it 'filters by date' do
        get service_appointments_path, params: { date: Date.today }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with status filter' do
      it 'filters by status' do
        get service_appointments_path, params: { status: 'agendado' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get service_appointments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /service_appointments/:id' do
    let(:appointment) { create(:service_appointment, customer: customer, employee: employee, service: service) }

    it 'returns success' do
      get service_appointment_path(appointment)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get service_appointment_path(appointment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /service_appointments/new' do
    it 'returns success' do
      get new_service_appointment_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_service_appointment_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /service_appointments' do
    let(:valid_attributes) do
      {
        service_id: service.id,
        employee_id: employee.id,
        customer_id: customer.id,
        appointment_date: 1.day.from_now.at_noon,
        status: 'agendado',
        duration_minutes: 60
      }
    end

    context 'with valid parameters' do
      it 'creates a new service appointment' do
        expect {
          post service_appointments_path, params: { service_appointment: valid_attributes }
        }.to change(ServiceAppointment, :count).by(1)
      end

      it 'redirects to the created appointment' do
        post service_appointments_path, params: { service_appointment: valid_attributes }
        expect(response).to redirect_to(ServiceAppointment.last)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(service_id: nil) }

      it 'does not create a new service appointment' do
        expect {
          post service_appointments_path, params: { service_appointment: invalid_attributes }
        }.not_to change(ServiceAppointment, :count)
      end

      it 'returns unprocessable_entity' do
        post service_appointments_path, params: { service_appointment: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post service_appointments_path, params: { service_appointment: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /service_appointments/:id/edit' do
    let(:appointment) { create(:service_appointment, customer: customer, employee: employee, service: service) }

    it 'returns success' do
      get edit_service_appointment_path(appointment)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_service_appointment_path(appointment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /service_appointments/:id' do
    let(:appointment) { create(:service_appointment, customer: customer, employee: employee, service: service, status: 'agendado') }

    context 'with valid parameters' do
      it 'updates the appointment' do
        patch service_appointment_path(appointment), params: { service_appointment: { status: 'concluido' } }
        appointment.reload
        expect(appointment.status).to eq('concluido')
      end

      it 'redirects to the appointment' do
        patch service_appointment_path(appointment), params: { service_appointment: { status: 'concluido' } }
        expect(response).to redirect_to(appointment)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch service_appointment_path(appointment), params: { service_appointment: { service_id: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch service_appointment_path(appointment), params: { service_appointment: { status: 'concluido' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /service_appointments/:id' do
    let!(:appointment) { create(:service_appointment, customer: customer, employee: employee, service: service) }

    it 'destroys the appointment' do
      expect {
        delete service_appointment_path(appointment)
      }.to change(ServiceAppointment, :count).by(-1)
    end

    it 'redirects to appointments list' do
      delete service_appointment_path(appointment)
      expect(response).to redirect_to(service_appointments_path)
    end

    context 'when destroy fails' do
      it 'shows an error message' do
        allow_any_instance_of(ServiceAppointment).to receive(:destroy).and_return(false)
        delete service_appointment_path(appointment)
        expect(flash[:alert]).to eq('Erro ao excluir agendamento.')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete service_appointment_path(appointment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /service_appointments/search_services' do
    before do
      create(:service, name: 'Corte de Cabelo', active: 'ativo')
      create(:service, name: 'Manicure', active: 'ativo')
      create(:service, name: 'Serviço Inativo', active: 'inativo')
    end

    it 'returns matching services as JSON' do
      get search_services_service_appointments_path, params: { query: 'Corte' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Corte de Cabelo')
    end

    it 'only returns active services' do
      get search_services_service_appointments_path, params: { query: 'Inativo' }
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_services_service_appointments_path, params: { query: 'Corte' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /service_appointments/search_employees' do
    before do
      create(:employee, full_name: 'Maria Silva', status: 'ativo')
      create(:employee, full_name: 'Ana Santos', status: 'ativo')
      create(:employee, full_name: 'Joana Costa', status: 'inativo')
    end

    it 'returns matching employees as JSON' do
      get search_employees_service_appointments_path, params: { query: 'Maria' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Maria Silva')
    end

    it 'only returns active employees' do
      get search_employees_service_appointments_path, params: { query: 'Costa' }
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_employees_service_appointments_path, params: { query: 'Maria' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /service_appointments/search_customers' do
    before do
      create(:customer, full_name: 'Carla Oliveira')
      create(:customer, full_name: 'Paula Souza')
    end

    it 'returns matching customers as JSON' do
      get search_customers_service_appointments_path, params: { query: 'Carla' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Carla Oliveira')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_customers_service_appointments_path, params: { query: 'Carla' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /service_appointments/check_conflicts' do
    let(:future_time) { 1.day.from_now.change(hour: 10, min: 0) }
    let(:existing_appointment) do
      create(:service_appointment,
             customer: customer,
             employee: employee,
             service: service,
             appointment_date: future_time,
             duration_minutes: 60,
             status: 'agendado')
    end

    context 'without conflicts' do
      it 'returns available true' do
        get check_conflicts_service_appointments_path, params: {
          employee_id: employee.id,
          start_time: 1.day.from_now.change(hour: 14, min: 0).iso8601,
          duration_minutes: 60
        }
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['available']).to be true
        expect(json['conflicts']).to be_empty
      end
    end

    context 'with conflicts' do
      it 'returns available false with conflict details' do
        existing_appointment # create the existing appointment

        get check_conflicts_service_appointments_path, params: {
          employee_id: employee.id,
          start_time: existing_appointment.appointment_date.iso8601,
          duration_minutes: 30
        }
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['available']).to be false
        expect(json['conflicts']).not_to be_empty
      end
    end

    context 'with missing parameters' do
      it 'returns available true when employee_id is missing' do
        get check_conflicts_service_appointments_path, params: {
          start_time: 1.day.from_now.change(hour: 10, min: 0).iso8601,
          duration_minutes: 60
        }
        json = JSON.parse(response.body)
        expect(json['available']).to be true
      end

      it 'returns available true when start_time is missing' do
        get check_conflicts_service_appointments_path, params: {
          employee_id: employee.id,
          duration_minutes: 60
        }
        json = JSON.parse(response.body)
        expect(json['available']).to be true
      end

      it 'returns available true when duration_minutes is zero' do
        get check_conflicts_service_appointments_path, params: {
          employee_id: employee.id,
          start_time: 1.day.from_now.change(hour: 10, min: 0).iso8601,
          duration_minutes: 0
        }
        json = JSON.parse(response.body)
        expect(json['available']).to be true
      end
    end

    context 'with exclude_id parameter' do
      it 'excludes the specified appointment from conflict check' do
        existing_appointment # create the existing appointment

        get check_conflicts_service_appointments_path, params: {
          employee_id: employee.id,
          start_time: existing_appointment.appointment_date.iso8601,
          duration_minutes: 30,
          exclude_id: existing_appointment.id
        }
        json = JSON.parse(response.body)
        expect(json['available']).to be true
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get check_conflicts_service_appointments_path, params: {
          employee_id: employee.id,
          start_time: 1.day.from_now.change(hour: 10, min: 0).iso8601,
          duration_minutes: 60
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
