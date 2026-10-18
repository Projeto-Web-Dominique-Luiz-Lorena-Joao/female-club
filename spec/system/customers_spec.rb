# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Customers', type: :system do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the customers list page' do
      visit customers_path

      expect(page).to have_content('Clientes')
      expect(page).to have_content('Gerenciar base de clientes')
      expect(page).to have_link('Novo Cliente')
    end

    it 'shows statistics cards' do
      visit customers_path

      expect(page).to have_content('Total de Clientes')
    end

    context 'with customers' do
      let!(:customer1) { create(:customer, full_name: 'Maria Silva') }
      let!(:customer2) { create(:customer, full_name: 'Ana Santos') }

      it 'displays customers in the table' do
        visit customers_path

        expect(page).to have_content('Maria Silva')
        expect(page).to have_content('Ana Santos')
      end

      it 'shows customer CPF' do
        visit customers_path

        expect(page).to have_content(customer1.formatted_cpf)
      end
    end

    context 'with search' do
      let!(:customer1) { create(:customer, full_name: 'Maria Silva') }
      let!(:customer2) { create(:customer, full_name: 'Ana Santos') }

      it 'filters customers by name' do
        visit customers_path

        fill_in 'search', with: 'Maria'
        click_button 'Buscar'

        expect(page).to have_content('Maria Silva')
        expect(page).not_to have_content('Ana Santos')
      end

      it 'clears search filter' do
        visit customers_path(search: 'Maria')

        click_link 'Limpar'

        expect(page).to have_content('Maria Silva')
        expect(page).to have_content('Ana Santos')
      end
    end

    context 'without customers' do
      it 'shows empty state message' do
        visit customers_path

        expect(page).to have_content('Nenhum cliente cadastrado')
      end
    end
  end

  describe 'Show page' do
    let(:customer) { create(:customer, full_name: 'Maria Silva') }

    it 'displays customer details' do
      visit customer_path(customer)

      expect(page).to have_content('Maria Silva')
      expect(page).to have_content(customer.formatted_cpf)
    end

    it 'has edit link' do
      visit customer_path(customer)

      expect(page).to have_link('Editar')
    end

    it 'has back link' do
      visit customer_path(customer)

      expect(page).to have_link('Voltar')
    end
  end

  describe 'New customer' do
    it 'displays the new customer form' do
      visit new_customer_path

      expect(page).to have_content('Novo Cliente')
      expect(page).to have_field('Nome Completo')
      expect(page).to have_field('CPF')
      expect(page).to have_field('Telefone')
    end

    it 'creates a new customer with valid data' do
      visit new_customer_path

      fill_in 'Nome Completo', with: 'Nova Cliente Teste'
      fill_in 'CPF', with: CPF.generate
      fill_in 'Telefone', with: '11999998888'

      click_button 'Salvar Cliente'

      expect(page).to have_content('Cliente cadastrado com sucesso')
      expect(page).to have_content('Nova Cliente Teste')
    end

    it 'shows validation errors with invalid data' do
      visit new_customer_path

      fill_in 'Nome Completo', with: ''
      click_button 'Salvar Cliente'

      expect(page).to have_content('não pode ficar em branco')
    end

    it 'has cancel link' do
      visit new_customer_path

      expect(page).to have_link('Cancelar')
    end
  end

  describe 'Edit customer' do
    let(:customer) { create(:customer, full_name: 'Maria Silva') }

    it 'displays the edit form with customer data' do
      visit edit_customer_path(customer)

      expect(page).to have_field('Nome Completo')
    end

    it 'updates customer with valid data' do
      visit edit_customer_path(customer)

      fill_in 'Nome Completo', with: 'Maria Silva Atualizada'
      click_button 'Salvar Cliente'

      expect(page).to have_content('Cliente atualizado com sucesso')
    end

    it 'shows validation errors with invalid data' do
      visit edit_customer_path(customer)

      fill_in 'Nome Completo', with: ''
      click_button 'Salvar Cliente'

      expect(page).to have_content('não pode ficar em branco')
    end
  end
end
