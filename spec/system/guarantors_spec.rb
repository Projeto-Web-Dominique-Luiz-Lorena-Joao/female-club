# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Guarantors', type: :system do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the guarantors list page' do
      visit guarantors_path

      expect(page).to have_content('Fiadores')
    end

    context 'with guarantors' do
      let(:customer) { create(:customer) }
      let!(:guarantor) { create(:guarantor, full_name: 'Fiador José', customer: customer) }

      it 'displays guarantors' do
        visit guarantors_path

        expect(page).to have_content('Fiador José')
      end
    end
  end

  describe 'Show page' do
    let(:customer) { create(:customer) }
    let(:guarantor) { create(:guarantor, full_name: 'Fiador Detalhe', customer: customer) }

    it 'displays guarantor details' do
      visit guarantor_path(guarantor)

      expect(page).to have_content('Fiador Detalhe')
    end
  end

  describe 'New guarantor' do
    it 'displays the new guarantor form' do
      visit new_guarantor_path

      expect(page).to have_field('Nome Completo')
      expect(page).to have_field('CPF')
      expect(page).to have_field('Telefone')
    end

    it 'creates a new guarantor with valid data' do
      visit new_guarantor_path

      fill_in 'Nome Completo', with: 'Novo Fiador Teste'
      fill_in 'CPF', with: generate_valid_cpf
      fill_in 'Telefone', with: '11988776655'

      click_button 'Salvar Fiador'

      expect(page).to have_content('Fiador cadastrado com sucesso')
    end

    it 'shows validation errors with invalid data' do
      visit new_guarantor_path

      fill_in 'Nome Completo', with: ''
      click_button 'Salvar Fiador'

      expect(page).to have_content('não pode ficar em branco')
    end
  end

  describe 'Edit guarantor' do
    let(:customer) { create(:customer) }
    let(:guarantor) { create(:guarantor, full_name: 'Fiador Editar', customer: customer) }

    it 'updates guarantor with valid data' do
      visit edit_guarantor_path(guarantor)

      fill_in 'Nome Completo', with: 'Fiador Atualizado'
      click_button 'Atualizar Fiador'

      expect(page).to have_content('Fiador atualizado com sucesso')
    end
  end
end
