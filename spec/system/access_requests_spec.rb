# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Access Requests', type: :system do
  describe 'Public request form' do
    it 'displays the access request form' do
      visit new_access_request_path

      expect(page).to have_content('Solicitar Acesso')
      expect(page).to have_field('E-mail')
      expect(page).to have_css('#password-field')
      expect(page).to have_field('Confirmar Senha')
      expect(page).to have_field('Mensagem de Justificativa')
      expect(page).to have_button('Solicitar Acesso')
    end

    it 'has link back to login' do
      visit new_access_request_path

      expect(page).to have_link('Entrar')
    end

    it 'submits request with valid data' do
      visit new_access_request_path

      fill_in 'E-mail', with: 'nova@usuario.com'
      fill_in 'password-field', with: 'Password123!'
      fill_in 'Confirmar Senha', with: 'Password123!'
      fill_in 'Mensagem de Justificativa', with: 'Preciso de acesso'

      click_button 'Solicitar Acesso'

      expect(page).to have_content('Solicitação enviada com sucesso')
    end

    it 'shows errors with invalid data' do
      visit new_access_request_path

      fill_in 'E-mail', with: ''
      click_button 'Solicitar Acesso'

      expect(page).to have_content('erro')
    end

    it 'displays password requirements hint' do
      visit new_access_request_path

      expect(page).to have_content('maiúsculas e minúsculas')
      expect(page).to have_content('caractere especial')
    end

    it 'rejects password without special character' do
      visit new_access_request_path

      fill_in 'E-mail', with: 'test@example.com'
      fill_in 'password-field', with: 'Password123'
      fill_in 'Confirmar Senha', with: 'Password123'
      click_button 'Solicitar Acesso'

      expect(page).to have_content('erro')
    end

    it 'rejects password without uppercase letter' do
      visit new_access_request_path

      fill_in 'E-mail', with: 'test@example.com'
      fill_in 'password-field', with: 'password123!'
      fill_in 'Confirmar Senha', with: 'password123!'
      click_button 'Solicitar Acesso'

      expect(page).to have_content('erro')
    end

    it 'accepts strong password meeting all criteria' do
      visit new_access_request_path

      fill_in 'E-mail', with: 'strong@password.com'
      fill_in 'password-field', with: 'StrongPass1!'
      fill_in 'Confirmar Senha', with: 'StrongPass1!'
      click_button 'Solicitar Acesso'

      expect(page).to have_content('Solicitação enviada com sucesso')
    end
  end

  describe 'Login page link' do
    it 'has solicitar acesso link' do
      visit new_user_session_path

      expect(page).to have_link('Solicitar acesso')
    end

    it 'solicitar acesso leads to request form' do
      visit new_user_session_path

      click_link 'Solicitar acesso'

      expect(page).to have_content('Solicitar Acesso')
      expect(page).to have_field('E-mail')
    end
  end

  describe 'Sign up redirects to request form' do
    it 'redirects /users/sign_up to access request' do
      visit '/users/sign_up'

      expect(page).to have_current_path(new_access_request_path)
    end
  end

  describe 'Admin management' do
    let(:user) { create(:user) }

    before do
      login_as(user, scope: :user)
    end

    it 'shows Solicitações in menu' do
      visit root_path

      expect(page).to have_link('Solicitações')
    end

    it 'displays the access requests page' do
      visit admin_access_requests_path

      expect(page).to have_content('Solicitações de Acesso')
    end

    context 'with pending request' do
      let!(:access_request) { create(:access_request, email: 'teste@pedido.com', message: 'Quero acessar') }

      it 'displays pending requests' do
        visit admin_access_requests_path

        expect(page).to have_content('teste@pedido.com')
        expect(page).to have_content('Quero acessar')
        expect(page).to have_content('Pendente')
      end

      it 'has approve and reject buttons' do
        visit admin_access_requests_path

        expect(page).to have_button('Aprovar')
        expect(page).to have_button('Rejeitar')
      end

      it 'shows badge with pending count in menu' do
        visit root_path

        within('aside') do
          expect(page).to have_content('1')
        end
      end

      it 'approves a request' do
        visit admin_access_requests_path

        click_button 'Aprovar'

        expect(page).to have_content('aprovada')
      end

      it 'rejects a request' do
        visit admin_access_requests_path

        click_button 'Rejeitar'

        expect(page).to have_content('rejeitada')
      end
    end

    context 'with status filters' do
      let!(:pending_req) { create(:access_request, email: 'pending@test.com') }
      let!(:approved_req) { create(:access_request, :approved, email: 'approved@test.com') }

      it 'filters by pending' do
        visit admin_access_requests_path(status: 'pending')

        expect(page).to have_content('pending@test.com')
        expect(page).not_to have_content('approved@test.com')
      end

      it 'filters by approved' do
        visit admin_access_requests_path(status: 'approved')

        expect(page).to have_content('approved@test.com')
        expect(page).not_to have_content('pending@test.com')
      end
    end

    context 'without requests' do
      it 'shows empty state' do
        visit admin_access_requests_path

        expect(page).to have_content('Nenhuma solicitação encontrada')
      end
    end
  end
end
