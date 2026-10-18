# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Services', type: :system do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the services list page' do
      visit services_path

      expect(page).to have_content('Serviços')
    end

    context 'with services' do
      let!(:service1) { create(:service, name: 'Corte Feminino', active: 'ativo') }
      let!(:service2) { create(:service, name: 'Manicure Completa', active: 'ativo') }

      it 'displays services in the list' do
        visit services_path

        expect(page).to have_content('Corte Feminino')
        expect(page).to have_content('Manicure Completa')
      end
    end
  end

  describe 'Show page' do
    let(:service) { create(:service, name: 'Corte Detalhe', price: 80) }

    it 'displays service details' do
      visit service_path(service)

      expect(page).to have_content('Corte Detalhe')
    end

    it 'has edit link' do
      visit service_path(service)

      expect(page).to have_link('Editar')
    end
  end

  describe 'New service' do
    it 'displays the new service form' do
      visit new_service_path

      expect(page).to have_field('Nome do Serviço')
      expect(page).to have_field('Preço do Serviço')
    end

    it 'creates a new service with valid data' do
      visit new_service_path

      fill_in 'Nome do Serviço', with: 'Escova Progressiva'
      fill_in 'Preço do Serviço', with: '150.00'
      fill_in 'Descrição', with: 'Tratamento capilar'

      click_button 'Criar Serviço'

      expect(page).to have_content('Serviço criado com sucesso')
    end

    it 'shows validation errors with invalid data' do
      visit new_service_path

      fill_in 'Nome do Serviço', with: ''
      click_button 'Criar Serviço'

      expect(page).to have_content('não pode ficar em branco')
    end
  end

  describe 'Edit service' do
    let(:service) { create(:service, name: 'Serviço Editar') }

    it 'displays the edit form' do
      visit edit_service_path(service)

      expect(page).to have_field('Nome do Serviço', with: 'Serviço Editar')
    end

    it 'updates service with valid data' do
      visit edit_service_path(service)

      fill_in 'Nome do Serviço', with: 'Serviço Atualizado'
      click_button 'Atualizar Serviço'

      expect(page).to have_content('Serviço atualizado com sucesso')
      expect(page).to have_content('Serviço Atualizado')
    end
  end
end
