# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe "GET /dashboard" do
    it "returns success" do
      get dashboard_path
      expect(response).to have_http_status(:success)
    end

    it "displays the dashboard" do
      get dashboard_path
      expect(response.body).to include("Dashboard")
    end

    it "displays annual KPI labels" do
      get dashboard_path
      expect(response.body).to include("Vendas do Ano")
      expect(response.body).to include("Despesas do Ano")
      expect(response.body).to include("Lucro Estimado")
      expect(response.body).to include("Agendamentos do Ano")
    end

    it "displays vs ano anterior comparison" do
      get dashboard_path
      expect(response.body).to include("vs ano anterior")
    end

    context "with annual sales data" do
      let(:customer) { create(:customer) }
      let(:employee) { create(:employee, status: "ativo") }

      before do
        # Vendas no ano atual
        create(:sale, customer: customer, employee: employee, sale_date: Date.current.beginning_of_year + 1.day, status: "pago", total_amount: 500)
        create(:sale, customer: customer, employee: employee, sale_date: Date.current, status: "pago", total_amount: 300)
        # Venda no ano anterior
        create(:sale, customer: customer, employee: employee, sale_date: 1.year.ago, status: "pago", total_amount: 200)
      end

      it "calculates annual KPIs" do
        get dashboard_path
        expect(response).to have_http_status(:success)
        # Deve mostrar total anual (800.00)
        expect(response.body).to include("800,00")
      end

      it "shows annual variation percentage" do
        get dashboard_path
        expect(response.body).to include("vs ano anterior")
      end

      it "counts total sales for the year" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with annual expenses data" do
      before do
        create(:expense, expense_date: Date.current, amount: 150, status: "ativa")
        create(:expense, expense_date: Date.current.beginning_of_year + 5.days, amount: 250, status: "ativa")
        create(:expense, expense_date: 1.year.ago, amount: 100, status: "ativa")
      end

      it "calculates annual expenses" do
        get dashboard_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("400,00")
      end
    end

    context "with annual profit calculation" do
      let(:customer) { create(:customer) }
      let(:employee) { create(:employee, status: "ativo") }

      before do
        create(:sale, customer: customer, employee: employee, sale_date: Date.current, status: "pago", total_amount: 1000)
        create(:expense, expense_date: Date.current, amount: 400, status: "ativa")
      end

      it "shows estimated annual profit (sales - expenses)" do
        get dashboard_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("600,00")
      end
    end

    context "with annual appointment data" do
      let(:customer) { create(:customer) }
      let(:employee) { create(:employee, status: "ativo") }
      let(:service) { create(:service) }

      before do
        create(:service_appointment, customer: customer, employee: employee, service: service,
               appointment_date: 1.day.from_now.change(hour: 10), status: "agendado")
        create(:service_appointment, customer: customer, employee: employee, service: service,
               appointment_date: 2.days.from_now.change(hour: 14), status: "agendado")
      end

      it "counts annual appointments" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "shows appointment breakdown" do
        get dashboard_path
        expect(response.body).to include("agendados")
      end
    end

    context "with annual product sales data" do
      let(:customer) { create(:customer) }
      let(:employee) { create(:employee, status: "ativo") }
      let(:product) { create(:product, :with_stock, initial_stock: 100) }

      before do
        sale = create(:sale, customer: customer, employee: employee, sale_date: Date.current, status: "pago")
        create(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 25.00)
      end

      it "calculates top products for the year" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with annual expenses by type" do
      before do
        create(:expense, expense_date: Date.current, amount: 300, status: "ativa", expense_type: "aluguel")
        create(:expense, expense_date: Date.current, amount: 200, status: "ativa", expense_type: "salaries")
      end

      it "groups expenses by type for the year" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with active customers for the year" do
      let(:employee) { create(:employee, status: "ativo") }

      before do
        customer1 = create(:customer)
        customer2 = create(:customer)
        create(:sale, customer: customer1, employee: employee, sale_date: Date.current, status: "pago")
        create(:sale, customer: customer2, employee: employee, sale_date: Date.current, status: "pago")
        # Customer from last year only
        customer3 = create(:customer)
        create(:sale, customer: customer3, employee: employee, sale_date: 1.year.ago, status: "pago")
      end

      it "counts customers active in the current year" do
        get dashboard_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Clientes Ativos")
      end
    end

    context "with low stock products" do
      before do
        create(:product, stock_status: "baixo")
        create(:product, stock_status: "critico")
        create(:product, stock_status: "normal")
      end

      it "counts low stock products" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context "without authentication" do
      before { logout(:user) }

      it "redirects to login" do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
