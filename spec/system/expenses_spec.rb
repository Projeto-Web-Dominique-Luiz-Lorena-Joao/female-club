# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Expenses', type: :system do
  let(:user) { create(:user) }
  let(:employee) { create(:employee, full_name: 'Func Despesa', status: 'ativo') }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the expenses list page' do
      visit expenses_path

      expect(page).to have_content('Despesas')
    end

    context 'with expenses' do
      before do
        create(:expense, employee: employee, expense_date: Date.today, amount: 500, status: 'ativa')
        create(:expense, employee: employee, expense_date: Date.today, amount: 300, status: 'ativa')
      end

      it 'displays expenses in the list' do
        visit expenses_path

        expect(page).to have_content('R$')
      end

      it 'filters by status' do
        visit expenses_path(status: 'ativa')

        expect(page).to have_http_status(:ok)
      end
    end
  end

  describe 'Show page' do
    let(:expense) { create(:expense, employee: employee, amount: 750) }

    it 'displays expense details' do
      visit expense_path(expense)

      expect(page).to have_content('Func Despesa')
    end

    it 'has edit and back links' do
      visit expense_path(expense)

      expect(page).to have_link('Editar')
      expect(page).to have_link('Voltar')
    end
  end

  describe 'New expense' do
    before { employee }

    it 'displays the new expense form' do
      visit new_expense_path

      expect(page).to have_content('Despesa')
      expect(page).to have_field('expense_expense_date')
      expect(page).to have_css('#expense_amount_display')
    end

    it 'shows the expense form fields' do
      visit new_expense_path

      expect(page).to have_content('Tipo de Despesa')
      expect(page).to have_content('Forma de Pagamento')
      expect(page).to have_content('Funcionário')
    end
  end

  describe 'Edit expense' do
    let(:expense) { create(:expense, employee: employee, amount: 500) }

    it 'displays the edit form' do
      visit edit_expense_path(expense)

      expect(page).to have_css('#expense_amount_display')
    end

    it 'displays expense type select' do
      visit edit_expense_path(expense)

      expect(page).to have_select('expense_expense_type')
    end
  end

  describe 'Cancel expense' do
    let!(:expense) { create(:expense, employee: employee, amount: 500, status: 'ativa') }

    it 'cancels an expense' do
      visit expense_path(expense)

      click_button 'Cancelar Despesa'

      expect(page).to have_content('inativada')
    end
  end
end
