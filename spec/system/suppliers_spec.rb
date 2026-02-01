# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Suppliers', type: :system do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the suppliers list page' do
      visit suppliers_path

      expect(page).to have_content('Fornecedores')
    end

    context 'with suppliers' do
      let!(:supplier1) { create(:supplier, legal_name: 'Fornecedor Alpha', trade_name: 'Alpha Cosméticos', status: :ativo) }
      let!(:supplier2) { create(:supplier, legal_name: 'Fornecedor Beta', trade_name: 'Beta Beauty', status: :ativo) }

      it 'displays suppliers' do
        visit suppliers_path

        expect(page).to have_content('Alpha')
        expect(page).to have_content('Beta')
      end

      it 'filters by category' do
        visit suppliers_path(category: 'cosmeticos')

        expect(page).to have_http_status(:ok)
      end
    end
  end

  describe 'Show page' do
    let(:supplier) { create(:supplier, legal_name: 'Fornecedor Detalhe', trade_name: 'Detalhe Co') }

    it 'displays supplier details' do
      visit supplier_path(supplier)

      expect(page).to have_content('Fornecedor Detalhe')
    end

    it 'has edit and back links' do
      visit supplier_path(supplier)

      expect(page).to have_link('Editar')
      expect(page).to have_link('Voltar')
    end
  end

  describe 'New supplier' do
    it 'displays the new supplier form' do
      visit new_supplier_path

      expect(page).to have_field('Razão Social')
      expect(page).to have_field('Nome Fantasia')
      expect(page).to have_field('Telefone')
    end

    it 'creates a new supplier with valid data' do
      visit new_supplier_path

      fill_in 'Razão Social', with: 'Novo Fornecedor Ltda'
      fill_in 'Nome Fantasia', with: 'Novo Fornecedor'
      fill_in 'Telefone', with: '11998877665'
      fill_in 'E-mail', with: 'novo@fornecedor.com'

      click_button 'Salvar Fornecedor'

      expect(page).to have_content('Fornecedor cadastrado com sucesso')
    end

    it 'shows validation errors with invalid data' do
      visit new_supplier_path

      fill_in 'Razão Social', with: ''
      click_button 'Salvar Fornecedor'

      expect(page).to have_content('não pode ficar em branco')
    end
  end

  describe 'Edit supplier' do
    let(:supplier) { create(:supplier, legal_name: 'Fornecedor Editar') }

    it 'displays the edit form' do
      visit edit_supplier_path(supplier)

      expect(page).to have_field('Razão Social', with: 'Fornecedor Editar')
    end

    it 'updates supplier with valid data' do
      visit edit_supplier_path(supplier)

      fill_in 'Razão Social', with: 'Fornecedor Atualizado'
      click_button 'Salvar Fornecedor'

      expect(page).to have_content('Fornecedor atualizado com sucesso')
      expect(page).to have_content('Fornecedor Atualizado')
    end
  end
end
