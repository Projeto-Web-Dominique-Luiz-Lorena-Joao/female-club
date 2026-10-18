# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Expenses', type: :request do
  let(:user) { create(:user) }
  let(:employee) { create(:employee, status: 'ativo') }
  let(:supplier) { create(:supplier) }

  before { login_as(user, scope: :user) }

  describe 'GET /expenses' do
    before do
      create_list(:expense, 3, employee: employee)
    end

    it 'returns success' do
      get expenses_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the expenses list' do
      get expenses_path
      expect(response.body).to include('Despesa')
    end

    context 'with employee_id filter' do
      it 'filters by employee' do
        get expenses_path, params: { employee_id: employee.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with supplier_id filter' do
      it 'filters by supplier' do
        get expenses_path, params: { supplier_id: supplier.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with expense_type filter' do
      it 'filters by expense type' do
        get expenses_path, params: { expense_type: 'fixa' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with category filter' do
      it 'filters by category' do
        get expenses_path, params: { category: 'aluguel' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with payment_method filter' do
      it 'filters by payment method' do
        get expenses_path, params: { payment_method: 'pix' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with date range filter' do
      it 'filters by date range' do
        get expenses_path, params: { start_date: 1.month.ago.to_date, end_date: Date.today }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with status filter' do
      it 'filters by status' do
        get expenses_path, params: { status: 'ativa' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get expenses_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /expenses/:id' do
    let(:expense) { create(:expense, employee: employee) }

    it 'returns success' do
      get expense_path(expense)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get expense_path(expense)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /expenses/new' do
    it 'returns success' do
      get new_expense_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_expense_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /expenses' do
    let(:valid_attributes) do
      {
        employee_id: employee.id,
        expense_date: Date.today,
        expense_type: 'aluguel',
        amount: 500.00,
        payment_method: 'pix',
        category: 'fixa_mensal',
        status: 'ativa'
      }
    end

    context 'with valid parameters' do
      it 'creates a new expense' do
        expect {
          post expenses_path, params: { expense: valid_attributes }
        }.to change(Expense, :count).by(1)
      end

      it 'redirects to the created expense' do
        post expenses_path, params: { expense: valid_attributes }
        expect(response).to redirect_to(Expense.last)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(amount: nil) }

      it 'does not create a new expense' do
        expect {
          post expenses_path, params: { expense: invalid_attributes }
        }.not_to change(Expense, :count)
      end

      it 'returns unprocessable_entity' do
        post expenses_path, params: { expense: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post expenses_path, params: { expense: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /expenses/:id/edit' do
    let(:expense) { create(:expense, employee: employee) }

    it 'returns success' do
      get edit_expense_path(expense)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_expense_path(expense)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /expenses/:id' do
    let(:expense) { create(:expense, employee: employee, amount: 100.00) }

    context 'with valid parameters' do
      it 'updates the expense' do
        patch expense_path(expense), params: { expense: { amount: 200.00 } }
        expense.reload
        expect(expense.amount).to eq(200.00)
      end

      it 'redirects to the expense' do
        patch expense_path(expense), params: { expense: { amount: 200.00 } }
        expect(response).to redirect_to(expense)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch expense_path(expense), params: { expense: { amount: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch expense_path(expense), params: { expense: { amount: 200.00 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /expenses/:id' do
    let!(:expense) { create(:expense, employee: employee) }

    it 'destroys the expense' do
      expect {
        delete expense_path(expense)
      }.to change(Expense, :count).by(-1)
    end

    it 'redirects to expenses list' do
      delete expense_path(expense)
      expect(response).to redirect_to(expenses_path)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete expense_path(expense)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /expenses/:id/cancel' do
    let(:expense) { create(:expense, employee: employee, status: 'ativa') }

    it 'cancels the expense' do
      patch cancel_expense_path(expense)
      expense.reload
      expect(expense.status).to eq('inativa')
    end

    it 'redirects to the expense' do
      patch cancel_expense_path(expense)
      expect(response).to redirect_to(expense)
    end

    it 'shows success notice' do
      patch cancel_expense_path(expense)
      expect(flash[:notice]).to eq('Despesa inativada com sucesso.')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch cancel_expense_path(expense)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /expenses/:id/reactivate' do
    let(:expense) { create(:expense, employee: employee, status: 'inativa') }

    it 'reactivates the expense' do
      patch reactivate_expense_path(expense)
      expense.reload
      expect(expense.status).to eq('ativa')
    end

    it 'redirects to the expense' do
      patch reactivate_expense_path(expense)
      expect(response).to redirect_to(expense)
    end

    it 'shows success notice' do
      patch reactivate_expense_path(expense)
      expect(flash[:notice]).to eq('Despesa reativada com sucesso.')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch reactivate_expense_path(expense)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
