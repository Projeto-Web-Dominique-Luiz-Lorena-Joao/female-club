# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Employees', type: :request do
  let(:user) { create(:user) }
  let(:valid_cpf) { CPF.generate }

  before { login_as(user, scope: :user) }

  describe 'GET /employees' do
    before do
      create_list(:employee, 3, status: 'ativo')
    end

    it 'returns success' do
      get employees_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the employees list' do
      get employees_path
      expect(response.body).to include('Funcionários')
    end

    context 'with status filter' do
      before do
        create(:employee, status: 'ativo')
        create(:employee, status: 'inativo')
      end

      it 'filters by status' do
        get employees_path, params: { status: 'ativo' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with position filter' do
      before do
        create(:employee, position: 'gerente')
        create(:employee, position: 'vendedor')
      end

      it 'filters by position' do
        get employees_path, params: { position: 'gerente' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with search' do
      before do
        create(:employee, full_name: 'Maria Silva')
        create(:employee, full_name: 'João Santos')
      end

      it 'searches by name' do
        get employees_path, params: { search: 'Maria' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by CPF digits' do
        employee = create(:employee)
        get employees_path, params: { search: employee.cpf[0..5] }
        expect(response).to have_http_status(:success)
      end

      it 'searches by email' do
        create(:employee, email: 'test@example.com')
        get employees_path, params: { search: 'test@example' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with sorting' do
      it 'sorts by admission date descending' do
        get employees_path, params: { sort_admission: 'desc' }
        expect(response).to have_http_status(:success)
      end

      it 'sorts by admission date ascending' do
        get employees_path, params: { sort_admission: 'asc' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get employees_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /employees/:id' do
    let(:employee) { create(:employee) }

    it 'returns success' do
      get employee_path(employee)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get employee_path(employee)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /employees/new' do
    it 'returns success' do
      get new_employee_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_employee_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /employees' do
    let(:valid_attributes) do
      {
        full_name: 'Maria Funcionária',
        cpf: valid_cpf,
        phone: '11999998888',
        position: 'vendedor',
        status: 'ativo',
        salary: 2500.00,
        admission_date: Date.today
      }
    end

    context 'with valid parameters' do
      it 'creates a new employee' do
        expect {
          post employees_path, params: { employee: valid_attributes }
        }.to change(Employee, :count).by(1)
      end

      it 'redirects to employees list' do
        post employees_path, params: { employee: valid_attributes }
        expect(response).to redirect_to(employees_path)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(full_name: '') }

      it 'does not create a new employee' do
        expect {
          post employees_path, params: { employee: invalid_attributes }
        }.not_to change(Employee, :count)
      end

      it 'returns unprocessable_entity' do
        post employees_path, params: { employee: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post employees_path, params: { employee: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /employees/:id/edit' do
    let(:employee) { create(:employee) }

    it 'returns success' do
      get edit_employee_path(employee)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_employee_path(employee)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /employees/:id' do
    let(:employee) { create(:employee, full_name: 'Nome Original') }

    context 'with valid parameters' do
      it 'updates the employee' do
        patch employee_path(employee), params: { employee: { full_name: 'Nome Atualizado' } }
        employee.reload
        expect(employee.full_name).to eq('Nome Atualizado')
      end

      it 'redirects to employees list' do
        patch employee_path(employee), params: { employee: { full_name: 'Nome Atualizado' } }
        expect(response).to redirect_to(employees_path)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch employee_path(employee), params: { employee: { full_name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'deleting photo' do
      let(:employee_with_photo) do
        e = create(:employee)
        e.photo.attach(
          io: StringIO.new('fake jpeg'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
        e
      end

      it 'removes the photo when requested' do
        expect(employee_with_photo.photo).to be_attached

        patch employee_path(employee_with_photo), params: {
          employee: { full_name: employee_with_photo.full_name, photo_delete: 'true' }
        }

        expect(response).to redirect_to(employees_path)
        employee_with_photo.reload
        expect(employee_with_photo.photo).not_to be_attached
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch employee_path(employee), params: { employee: { full_name: 'Nome' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /employees/:id' do
    let!(:employee) { create(:employee, status: 'ativo') }

    it 'inactivates the employee instead of destroying' do
      expect {
        delete employee_path(employee)
      }.not_to change(Employee, :count)

      employee.reload
      expect(employee.status).to eq('inativo')
    end

    it 'redirects to employees list' do
      delete employee_path(employee)
      expect(response).to redirect_to(employees_path)
    end

    context 'when inactivation fails' do
      it 'shows an error message' do
        allow_any_instance_of(Employee).to receive(:update).and_return(false)
        delete employee_path(employee)
        expect(flash[:alert]).to eq('Não foi possível inativar o funcionário.')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete employee_path(employee)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /employees/:id/reactivate' do
    let(:inactive_employee) { create(:employee, status: 'inativo') }

    it 'reactivates the employee' do
      patch reactivate_employee_path(inactive_employee)
      inactive_employee.reload
      expect(inactive_employee.status).to eq('ativo')
    end

    it 'redirects to the employee' do
      patch reactivate_employee_path(inactive_employee)
      expect(response).to redirect_to(inactive_employee)
    end

    it 'shows success notice' do
      patch reactivate_employee_path(inactive_employee)
      expect(flash[:notice]).to eq('Funcionário reativado com sucesso!')
    end

    context 'when reactivation fails' do
      it 'shows an error message' do
        allow_any_instance_of(Employee).to receive(:update).and_return(false)
        patch reactivate_employee_path(inactive_employee)
        expect(flash[:alert]).to eq('Não foi possível reativar o funcionário.')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch reactivate_employee_path(inactive_employee)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
