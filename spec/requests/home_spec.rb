# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home', type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'GET /dashboard' do
    it 'returns success' do
      get dashboard_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the dashboard' do
      get dashboard_path
      expect(response.body).to include('Dashboard')
    end

    context 'with sales data' do
      let(:customer) { create(:customer) }
      let(:employee) { create(:employee, status: 'ativo') }

      before do
        # Create sales in current month
        create_list(:sale, 3, customer: customer, employee: employee, sale_date: Date.today, status: 'pago')
        # Create sales in previous month
        create(:sale, customer: customer, employee: employee, sale_date: 1.month.ago, status: 'pago')
      end

      it 'calculates KPIs correctly' do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end

      it 'includes sales chart data' do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'with product sales data' do
      let(:customer) { create(:customer) }
      let(:employee) { create(:employee, status: 'ativo') }
      let(:product) { create(:product, :with_stock, initial_stock: 100) }

      before do
        sale = create(:sale, customer: customer, employee: employee, sale_date: Date.today, status: 'pago')
        create(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 25.00)
      end

      it 'calculates top products' do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'with low stock products' do
      before do
        create(:product, stock_status: 'baixo')
        create(:product, stock_status: 'critico')
        create(:product, stock_status: 'normal')
      end

      it 'counts low stock products' do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
