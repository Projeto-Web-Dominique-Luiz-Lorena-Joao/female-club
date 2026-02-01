# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sales', type: :system do
  let(:user) { create(:user) }
  let(:customer) { create(:customer, full_name: 'Cliente Venda') }
  let(:employee) { create(:employee, full_name: 'Vendedora Maria', status: 'ativo') }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the sales list page' do
      visit sales_path

      expect(page).to have_content('Vendas')
    end

    context 'with sales' do
      before do
        create(:sale, customer: customer, employee: employee, sale_date: Date.today, status: 'pago', total_amount: 150)
        create(:sale, customer: customer, employee: employee, sale_date: Date.today, status: 'pendente', total_amount: 80)
      end

      it 'displays sales in the list' do
        visit sales_path

        expect(page).to have_content('R$')
      end

      it 'filters by status' do
        visit sales_path(status: 'pago')

        expect(page).to have_content('R$')
      end

      it 'filters by payment method' do
        visit sales_path(payment_method: 'pix')

        expect(page).to have_http_status(:ok)
      end

      it 'filters by date range' do
        visit sales_path(start_date: 1.week.ago.to_date, end_date: Date.today)

        expect(page).to have_http_status(:ok)
      end
    end
  end

  describe 'Show page' do
    let(:sale) { create(:sale, customer: customer, employee: employee, total_amount: 250) }

    it 'displays sale details' do
      visit sale_path(sale)

      expect(page).to have_content('Cliente Venda')
      expect(page).to have_content('Vendedora Maria')
    end

    it 'has edit and back links' do
      visit sale_path(sale)

      expect(page).to have_link('Editar')
      expect(page).to have_link('Voltar')
    end

    context 'when sale is pending' do
      let(:pending_sale) { create(:sale, :pendente, customer: customer, employee: employee) }

      it 'has mark as paid button' do
        visit sale_path(pending_sale)

        expect(page).to have_button('Marcar como paga')
      end

      it 'marks sale as paid' do
        visit sale_path(pending_sale)

        click_button 'Marcar como paga'

        expect(page).to have_content('Venda marcada como paga')
      end
    end
  end

  describe 'New sale' do
    before do
      customer
      employee
    end

    it 'displays the new sale form' do
      visit new_sale_path

      expect(page).to have_content('Nova Venda')
      expect(page).to have_field('Data da Venda')
      expect(page).to have_field('Valor Total')
    end

    it 'shows payment method options' do
      visit new_sale_path

      expect(page).to have_select('Forma de Pagamento', options: ['Selecione uma opção', 'Dinheiro', 'Cartão de Crédito', 'Cartão de Débito', 'PIX', 'Transferência', 'Boleto'])
    end

    it 'shows status options' do
      visit new_sale_path

      expect(page).to have_select('Status', with_options: ['Pendente', 'Pago', 'Cancelado'])
    end
  end

  describe 'Edit sale' do
    let(:sale) { create(:sale, customer: customer, employee: employee, total_amount: 200) }

    it 'displays the edit form with sale data' do
      visit edit_sale_path(sale)

      expect(page).to have_field('Valor Total')
    end

    it 'updates sale with valid data' do
      visit edit_sale_path(sale)

      fill_in 'Valor Total', with: '300.00'
      click_button 'Salvar Venda'

      expect(page).to have_content('Venda atualizada com sucesso')
    end
  end
end
