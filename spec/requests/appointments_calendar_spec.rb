# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AppointmentsCalendar', type: :request do
  let(:user) { create(:user) }
  let(:customer) { create(:customer) }
  let(:employee) { create(:employee, status: 'ativo') }
  let(:service) { create(:service, active: 'ativo') }

  before { login_as(user, scope: :user) }

  describe 'GET /appointments_calendar' do
    it 'returns success' do
      get appointments_calendar_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the calendar' do
      get appointments_calendar_path
      expect(response.body).to include('Calendário')
    end

    context 'with year and month parameters' do
      it 'shows calendar for specific month' do
        get appointments_calendar_path, params: { year: 2026, month: 3 }
        expect(response).to have_http_status(:success)
      end

      it 'shows calendar for different year' do
        get appointments_calendar_path, params: { year: 2025, month: 6 }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with appointments' do
      before do
        # Create appointments for next month to avoid past date validation
        next_month = 1.month.from_now.beginning_of_month + 10.days
        create(:service_appointment,
               customer: customer,
               employee: employee,
               service: service,
               appointment_date: next_month.change(hour: 10))
        create(:service_appointment,
               customer: customer,
               employee: employee,
               service: service,
               appointment_date: next_month.change(hour: 14))
      end

      it 'groups appointments by day' do
        next_month = 1.month.from_now
        get appointments_calendar_path, params: { year: next_month.year, month: next_month.month }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get appointments_calendar_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when Brazilian holidays API fails' do
      it 'handles API error gracefully' do
        allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('Connection error'))
        get appointments_calendar_path
        expect(response).to have_http_status(:success)
      end

      it 'handles non-success response' do
        mock_response = instance_double(Net::HTTPNotFound, is_a?: false)
        allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(Net::HTTP).to receive(:get_response).and_return(mock_response)
        get appointments_calendar_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
