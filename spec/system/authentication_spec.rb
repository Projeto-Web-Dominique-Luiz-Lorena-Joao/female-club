# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication', type: :system do
  describe 'Login' do
    let(:user) { create(:user) }

    it 'displays the login page' do
      visit new_user_session_path

      expect(page).to have_content('Bem-vinda')
      expect(page).to have_content('Entre com suas credenciais')
      expect(page).to have_field('Email')
      expect(page).to have_css('#password-field')
      expect(page).to have_button('Entrar')
    end

    it 'allows user to login with valid credentials' do
      visit new_user_session_path

      fill_in 'Email', with: user.email
      fill_in 'password-field', with: 'Password123!'
      click_button 'Entrar'

      expect(page).to have_content('Dashboard')
    end

    it 'shows error message with invalid credentials' do
      visit new_user_session_path

      fill_in 'Email', with: user.email
      fill_in 'password-field', with: 'wrong_password'
      click_button 'Entrar'

      expect(page).to have_content('E-mail ou senha inválidos')
    end

    it 'shows error message with non-existent email' do
      visit new_user_session_path

      fill_in 'Email', with: 'nonexistent@example.com'
      fill_in 'password-field', with: 'Password123!'
      click_button 'Entrar'

      expect(page).to have_content('E-mail ou senha inválidos')
    end

    it 'has link to forgot password' do
      visit new_user_session_path

      expect(page).to have_link('Esqueceu a senha?')
    end

    it 'has link to register' do
      visit new_user_session_path

      expect(page).to have_link('Solicitar acesso')
    end
  end

  describe 'Logout' do
    let(:user) { create(:user) }

    before do
      login_as(user, scope: :user)
    end

    it 'allows user to logout' do
      visit root_path

      click_button 'Sair'

      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe 'Protected routes' do
    it 'redirects to login when accessing dashboard without authentication' do
      visit root_path

      expect(page).to have_current_path(new_user_session_path)
    end

    it 'redirects to login when accessing customers without authentication' do
      visit customers_path

      expect(page).to have_current_path(new_user_session_path)
    end

    it 'redirects to login when accessing sales without authentication' do
      visit sales_path

      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
