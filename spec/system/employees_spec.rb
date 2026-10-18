# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Employees', type: :system do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the employees list page' do
      visit employees_path

      expect(page).to have_content('Funcionários')
      expect(page).to have_link('Novo Funcionário')
    end

    context 'with employees' do
      let!(:employee) { create(:employee, full_name: 'Funcionária Ana', status: 'ativo') }
      let!(:inactive_employee) { create(:employee, full_name: 'Funcionária Bela', status: 'inativo') }

      it 'displays active employees' do
        visit employees_path

        expect(page).to have_content('Funcionária Ana')
      end

      it 'filters by status' do
        visit employees_path(status: 'inativo')

        expect(page).to have_content('Funcionária Bela')
      end

      it 'searches by name' do
        visit employees_path

        fill_in 'search', with: 'Ana'
        click_button 'Buscar'

        expect(page).to have_content('Funcionária Ana')
      end
    end
  end

  describe 'Show page' do
    let(:employee) { create(:employee, full_name: 'Funcionária Teste') }

    it 'displays employee details' do
      visit employee_path(employee)

      expect(page).to have_content('Funcionária Teste')
      expect(page).to have_content(employee.formatted_cpf)
    end

    it 'has edit and back links' do
      visit employee_path(employee)

      expect(page).to have_link('Editar')
      expect(page).to have_link('Voltar')
    end
  end

  describe 'New employee' do
    it 'displays the new employee form' do
      visit new_employee_path

      expect(page).to have_content('Dados do Funcionário')
      expect(page).to have_field('Nome Completo')
      expect(page).to have_field('CPF')
      expect(page).to have_field('Telefone')
    end

    it 'creates a new employee with valid data' do
      visit new_employee_path

      fill_in 'Nome Completo', with: 'Nova Funcionária'
      fill_in 'CPF', with: generate_valid_cpf
      fill_in 'Telefone', with: '11999887766'
      fill_in 'E-mail', with: 'nova@func.com'
      select 'Cabeleireira', from: 'Cargo'
      fill_in 'Data de Admissão', with: Date.today.strftime('%Y-%m-%d')
      fill_in 'Salário (R$)', with: '3000.00'

      click_button 'Salvar Funcionário'

      expect(page).to have_content('Funcionário cadastrado com sucesso')
    end

    it 'shows validation errors with invalid data' do
      visit new_employee_path

      fill_in 'Nome Completo', with: ''
      click_button 'Salvar Funcionário'

      expect(page).to have_content('erro')
    end
  end

  describe 'Edit employee' do
    let(:employee) { create(:employee, full_name: 'Funcionária Editar') }

    it 'displays the edit form with employee data' do
      visit edit_employee_path(employee)

      expect(page).to have_field('Nome Completo', with: 'Funcionária Editar')
    end

    it 'updates employee with valid data' do
      visit edit_employee_path(employee)

      fill_in 'Nome Completo', with: 'Funcionária Atualizada'
      click_button 'Salvar Funcionário'

      expect(page).to have_content('Funcionário atualizado com sucesso')
      expect(page).to have_content('Funcionária Atualizada')
    end
  end

  describe 'Inactivate employee' do
    let!(:employee) { create(:employee, full_name: 'Func Inativar', status: 'ativo') }

    it 'inactivates an employee' do
      visit employee_path(employee)

      click_button 'Inativar Funcionário'

      expect(page).to have_content('inativado')
    end
  end
end
