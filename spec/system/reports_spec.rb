# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports', type: :system do
  let(:user) { create(:user) }
  let(:customer) { create(:customer) }
  let(:employee) { create(:employee, status: 'ativo') }

  before do
    login_as(user, scope: :user)
  end

  describe 'Daily Reports' do
    it 'displays the daily report page' do
      visit daily_reports_path

      expect(page).to have_content('Relatório')
    end

    it 'allows selecting a specific date' do
      visit daily_reports_path(date: 1.day.ago.to_date)

      expect(page).to have_http_status(:ok)
    end

    context 'with sales data' do
      before do
        create(:sale, customer: customer, employee: employee, sale_date: Date.today, status: 'pago', total_amount: 500)
      end

      it 'shows sales statistics' do
        visit daily_reports_path

        expect(page).to have_content('R$')
      end
    end

    context 'with expenses data' do
      before do
        create(:expense, employee: employee, expense_date: Date.today, status: 'ativa', amount: 200)
      end

      it 'shows expenses in report' do
        visit daily_reports_path

        expect(page).to have_content('R$')
      end
    end
  end

  describe 'Monthly Reports' do
    it 'displays the monthly report page' do
      visit monthly_reports_path

      expect(page).to have_content('Relatório')
    end

    it 'allows selecting a specific month' do
      visit monthly_reports_path(month: 1.month.ago.month, year: 1.month.ago.year)

      expect(page).to have_http_status(:ok)
    end

    context 'with sales data' do
      before do
        create(:sale, customer: customer, employee: employee,
               sale_date: Date.today.beginning_of_month + 5.days,
               status: 'pago', total_amount: 1000)
      end

      it 'shows monthly statistics' do
        visit monthly_reports_path

        expect(page).to have_content('R$')
      end
    end
  end

  describe 'Yearly Reports' do
    it 'displays the yearly report page' do
      visit yearly_reports_path

      expect(page).to have_content('Relatório')
    end

    it 'allows selecting a specific year' do
      visit yearly_reports_path(year: 1.year.ago.year)

      expect(page).to have_http_status(:ok)
    end

    context 'with sales data' do
      before do
        create(:sale, customer: customer, employee: employee,
               sale_date: Date.today.beginning_of_year + 30.days,
               status: 'pago', total_amount: 5000)
      end

      it 'shows yearly statistics' do
        visit yearly_reports_path

        expect(page).to have_content('R$')
      end
    end

    context 'with expenses data' do
      before do
        create(:expense, employee: employee,
               expense_date: Date.today.beginning_of_year + 15.days,
               status: 'ativa', amount: 2000)
      end

      it 'shows expenses in yearly report' do
        visit yearly_reports_path

        expect(page).to have_content('R$')
      end
    end
  end
end
