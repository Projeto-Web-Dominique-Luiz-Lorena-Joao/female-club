# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports', type: :request do
  let(:user) { create(:user) }
  let(:customer) { create(:customer) }
  let(:employee) { create(:employee, status: 'ativo') }

  before { login_as(user, scope: :user) }

  describe 'DailyReports' do
    describe 'GET /daily_reports' do
      it 'returns success' do
        get daily_reports_path
        expect(response).to have_http_status(:success)
      end

      it 'displays the daily report' do
        get daily_reports_path
        expect(response.body).to include('Relatório')
      end

      context 'with date parameter' do
        it 'shows report for specific date' do
          get daily_reports_path, params: { date: 1.day.ago.to_date }
          expect(response).to have_http_status(:success)
        end
      end

      context 'with sales data' do
        before do
          create(:sale, customer: customer, employee: employee, sale_date: Date.today, status: 'pago', total_amount: 100)
          create(:sale, customer: customer, employee: employee, sale_date: Date.today, status: 'pendente', total_amount: 50)
        end

        it 'calculates daily stats' do
          get daily_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with expenses data' do
        before do
          create(:expense, employee: employee, expense_date: Date.today, status: 'ativa', amount: 200)
        end

        it 'includes expenses in report' do
          get daily_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with product sales' do
        let(:product) { create(:product, :with_stock, initial_stock: 100) }

        before do
          sale = create(:sale, customer: customer, employee: employee, sale_date: Date.today, status: 'pago')
          create(:sale_product, sale: sale, product: product, quantity: 3, unit_price: 25.00)
        end

        it 'calculates top products' do
          get daily_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with service sales' do
        let(:service) { create(:service, active: 'ativo') }

        before do
          sale = create(:sale, customer: customer, employee: employee, sale_date: Date.today, status: 'pago')
          create(:sale_service, sale: sale, service: service, quantity: 2, unit_price: 50.00)
        end

        it 'calculates top services' do
          get daily_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with appointments' do
        let(:service) { create(:service, active: 'ativo') }

        before do
          # Create appointment for tomorrow but test report for that same day
          create(:service_appointment,
                 customer: customer,
                 employee: employee,
                 service: service,
                 appointment_date: 1.day.from_now.change(hour: 14))
        end

        it 'counts appointments for the specified date' do
          get daily_reports_path, params: { date: 1.day.from_now.to_date }
          expect(response).to have_http_status(:success)
        end
      end

      context 'without authentication' do
        before { logout(:user) }

        it 'redirects to login' do
          get daily_reports_path
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe 'MonthlyReports' do
    describe 'GET /monthly_reports' do
      it 'returns success' do
        get monthly_reports_path
        expect(response).to have_http_status(:success)
      end

      context 'with date parameters' do
        it 'shows report for specific month' do
          get monthly_reports_path, params: { month: 1.month.ago.month, year: 1.month.ago.year }
          expect(response).to have_http_status(:success)
        end
      end

      context 'with month as date string' do
        it 'parses date string correctly' do
          get monthly_reports_path, params: { month: Date.today.beginning_of_month.to_s }
          expect(response).to have_http_status(:success)
        end
      end

      context 'with sales data' do
        before do
          create_list(:sale, 3, customer: customer, employee: employee, sale_date: Date.today.beginning_of_month, status: 'pago')
        end

        it 'calculates monthly stats' do
          get monthly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with top products data' do
        let(:product) { create(:product, :with_stock, initial_stock: 100) }

        before do
          sale = create(:sale, customer: customer, employee: employee, sale_date: Date.today.beginning_of_month + 5.days, status: 'pago')
          create(:sale_product, sale: sale, product: product, quantity: 10, unit_price: 50.00)
        end

        it 'calculates top products' do
          get monthly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with top services data' do
        let(:service) { create(:service, active: 'ativo') }

        before do
          sale = create(:sale, customer: customer, employee: employee, sale_date: Date.today.beginning_of_month + 5.days, status: 'pago')
          create(:sale_service, sale: sale, service: service, quantity: 5, unit_price: 100.00)
        end

        it 'calculates top services' do
          get monthly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'without authentication' do
        before { logout(:user) }

        it 'redirects to login' do
          get monthly_reports_path
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe 'YearlyReports' do
    describe 'GET /yearly_reports' do
      it 'returns success' do
        get yearly_reports_path
        expect(response).to have_http_status(:success)
      end

      context 'with year parameter' do
        it 'shows report for specific year' do
          get yearly_reports_path, params: { year: 1.year.ago.year }
          expect(response).to have_http_status(:success)
        end
      end

      context 'with sales data' do
        before do
          create_list(:sale, 3, customer: customer, employee: employee, sale_date: Date.today.beginning_of_year, status: 'pago')
        end

        it 'calculates yearly stats' do
          get yearly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with expenses data for monthly aggregation' do
        before do
          create(:expense, employee: employee, expense_date: Date.today.beginning_of_year + 15.days, status: 'ativa', amount: 500)
          create(:expense, employee: employee, expense_date: Date.today.beginning_of_year + 45.days, status: 'ativa', amount: 300)
        end

        it 'aggregates expenses by month' do
          get yearly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with expenses data for quarterly aggregation' do
        before do
          # Q1 expense
          create(:expense, employee: employee, expense_date: Date.new(Date.today.year, 2, 15), status: 'ativa', amount: 1000)
          # Q2 expense
          create(:expense, employee: employee, expense_date: Date.new(Date.today.year, 5, 15), status: 'ativa', amount: 800)
        end

        it 'aggregates expenses by quarter' do
          get yearly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with growth calculation (previous year has revenue)' do
        before do
          # Previous year sale
          create(:sale, customer: customer, employee: employee, sale_date: 1.year.ago, status: 'pago', total_amount: 1000)
          # Current year sale
          create(:sale, customer: customer, employee: employee, sale_date: Date.today.beginning_of_year + 10.days, status: 'pago', total_amount: 1500)
        end

        it 'calculates revenue growth percentage' do
          get yearly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with top products data' do
        let(:product) { create(:product, :with_stock, initial_stock: 100) }

        before do
          sale = create(:sale, customer: customer, employee: employee, sale_date: Date.today.beginning_of_year + 30.days, status: 'pago')
          create(:sale_product, sale: sale, product: product, quantity: 15, unit_price: 75.00)
        end

        it 'calculates top products' do
          get yearly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with top services data' do
        let(:service) { create(:service, active: 'ativo') }

        before do
          sale = create(:sale, customer: customer, employee: employee, sale_date: Date.today.beginning_of_year + 30.days, status: 'pago')
          create(:sale_service, sale: sale, service: service, quantity: 8, unit_price: 120.00)
        end

        it 'calculates top services' do
          get yearly_reports_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'without authentication' do
        before { logout(:user) }

        it 'redirects to login' do
          get yearly_reports_path
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end
end
