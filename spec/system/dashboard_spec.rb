# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe "Dashboard page" do
    it "displays the dashboard" do
      visit root_path

      expect(page).to have_content("Dashboard")
      expect(page).to have_content("Visão geral do seu negócio")
    end

    it "shows annual KPI cards" do
      visit root_path

      expect(page).to have_content("Vendas do Ano")
      expect(page).to have_content("Despesas do Ano")
      expect(page).to have_content("Lucro Estimado")
      expect(page).to have_content("Agendamentos Hoje")
      expect(page).to have_content("Total de Vendas")
      expect(page).to have_content("Clientes Ativos")
      expect(page).to have_content("Estoque Baixo")
      expect(page).to have_content("Agendamentos do Ano")
    end

    it "shows annual comparison labels" do
      visit root_path

      expect(page).to have_content("vs ano anterior")
    end

    context "with sales data" do
      let(:customer) { create(:customer) }
      let(:employee) { create(:employee, status: "ativo") }

      before do
        create(:sale, customer: customer, employee: employee, sale_date: Date.current, status: "pago", total_amount: 500)
        create(:sale, customer: customer, employee: employee, sale_date: Date.current, status: "pago", total_amount: 300)
      end

      it "displays annual sales statistics" do
        visit root_path

        expect(page).to have_content("R$")
        expect(page).to have_content("800,00")
      end
    end

    context "with customers data" do
      let(:employee) { create(:employee, status: "ativo") }

      before do
        customer = create(:customer)
        create(:sale, customer: customer, employee: employee, sale_date: Date.current, status: "pago")
      end

      it "displays active customer count for the year" do
        visit root_path

        expect(page).to have_content("Clientes Ativos")
      end
    end

    it "shows bottom panels" do
      visit root_path

      expect(page).to have_content("Próximos Agendamentos")
      expect(page).to have_content("Vendas Recentes")
      expect(page).to have_content("Despesas por Tipo")
    end
  end

  describe "Navigation" do
    it "has navigation menu" do
      visit root_path

      expect(page).to have_link("Dashboard")
      expect(page).to have_link("Vendas")
      expect(page).to have_link("Clientes")
      expect(page).to have_link("Produtos")
    end

    it "navigates to customers page" do
      visit root_path

      click_link "Clientes"

      expect(page).to have_current_path(customers_path)
    end

    it "navigates to sales page" do
      visit root_path

      click_link "Vendas"

      expect(page).to have_current_path(sales_path)
    end

    it "navigates to products page" do
      visit root_path

      click_link "Produtos"

      expect(page).to have_current_path(products_path)
    end
  end
end
