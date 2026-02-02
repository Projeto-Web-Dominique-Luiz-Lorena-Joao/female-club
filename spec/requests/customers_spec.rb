# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Customers', type: :request do
  let(:user) { create(:user) }
  let(:valid_cpf) { CPF.generate }

  before { login_as(user, scope: :user) }

  describe 'GET /customers' do
    before do
      create_list(:customer, 3)
    end

    it 'returns success' do
      get customers_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the customers list' do
      get customers_path
      expect(response.body).to include('Cliente')
    end

    context 'with search' do
      before do
        create(:customer, full_name: 'Maria Oliveira')
        create(:customer, full_name: 'João Santos')
      end

      it 'searches by name' do
        get customers_path, params: { search: 'Maria' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by email' do
        create(:customer, email: 'test@example.com')
        get customers_path, params: { search: 'test@example' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by phone digits' do
        customer = create(:customer, phone_number: '11999887766')
        get customers_path, params: { search: '999887' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by CPF digits' do
        customer = create(:customer)
        get customers_path, params: { search: customer.cpf[0..5] }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with tier filter' do
      it 'filters VIP customers' do
        get customers_path, params: { tier: 'vip' }
        expect(response).to have_http_status(:success)
      end

      it 'filters active customers' do
        get customers_path, params: { tier: 'active' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get customers_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /customers/:id' do
    let(:customer) { create(:customer) }

    it 'returns success' do
      get customer_path(customer)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get customer_path(customer)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /customers/new' do
    it 'returns success' do
      get new_customer_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_customer_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /customers' do
    let(:valid_attributes) do
      {
        full_name: 'Maria Cliente',
        cpf: valid_cpf,
        phone_number: '11999998888',
        email: 'maria@example.com'
      }
    end

    context 'with valid parameters (HTML)' do
      it 'creates a new customer' do
        expect {
          post customers_path, params: { customer: valid_attributes }
        }.to change(Customer, :count).by(1)
      end

      it 'redirects to customers list' do
        post customers_path, params: { customer: valid_attributes }
        expect(response).to redirect_to(customers_path)
      end
    end

    context 'with valid parameters (JSON)' do
      it 'creates a new customer' do
        expect {
          post customers_path, params: { customer: valid_attributes }, as: :json
        }.to change(Customer, :count).by(1)
      end

      it 'returns created status' do
        post customers_path, params: { customer: valid_attributes }, as: :json
        expect(response).to have_http_status(:created)
      end

      it 'returns customer data' do
        post customers_path, params: { customer: valid_attributes }, as: :json
        json = JSON.parse(response.body)
        expect(json['full_name']).to eq('Maria Cliente')
      end
    end

    context 'with guarantor' do
      let(:guarantor_params) do
        {
          full_name: 'Fiador Teste',
          cpf: CPF.generate,
          phone: '11888887777',
          relationship: 'pai'
        }
      end

      it 'creates a customer with guarantor' do
        expect {
          post customers_path, params: { customer: valid_attributes, guarantor: guarantor_params }
        }.to change(Customer, :count).by(1).and change(Guarantor, :count).by(1)
      end
    end

    context 'with invalid parameters (HTML)' do
      let(:invalid_attributes) { valid_attributes.merge(full_name: '') }

      it 'does not create a new customer' do
        expect {
          post customers_path, params: { customer: invalid_attributes }
        }.not_to change(Customer, :count)
      end

      it 'returns unprocessable_entity' do
        post customers_path, params: { customer: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid parameters (JSON)' do
      let(:invalid_attributes) { valid_attributes.merge(full_name: '') }

      it 'returns unprocessable_entity' do
        post customers_path, params: { customer: invalid_attributes }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors' do
        post customers_path, params: { customer: invalid_attributes }, as: :json
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'with phone parameter (alias)' do
      it 'converts phone to phone_number' do
        post customers_path, params: { customer: valid_attributes.merge(phone: '11888887777').except(:phone_number) }
        expect(Customer.last.phone_number).to eq('11888887777')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post customers_path, params: { customer: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when an unexpected error occurs (HTML)' do
      it 'handles the error gracefully' do
        allow_any_instance_of(CustomersController).to receive(:create_or_update_guarantor).and_raise(StandardError.new('Unexpected error'))
        guarantor_params = { full_name: 'Test Guarantor', cpf: CPF.generate, phone: '11999998888', relationship: 'pai' }
        post customers_path, params: { customer: valid_attributes, guarantor: guarantor_params }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when an unexpected error occurs (JSON)' do
      it 'returns error in JSON format' do
        allow_any_instance_of(CustomersController).to receive(:create_or_update_guarantor).and_raise(StandardError.new('Unexpected error'))
        guarantor_params = { full_name: 'Test Guarantor', cpf: CPF.generate, phone: '11999998888', relationship: 'pai' }
        post customers_path, params: { customer: valid_attributes, guarantor: guarantor_params }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Erro interno ao processar a requisição.')
      end
    end
  end

  describe 'GET /customers/:id/edit' do
    let(:customer) { create(:customer) }

    it 'returns success' do
      get edit_customer_path(customer)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_customer_path(customer)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /customers/:id' do
    let(:customer) { create(:customer, full_name: 'Nome Original') }

    context 'with valid parameters' do
      it 'updates the customer' do
        patch customer_path(customer), params: { customer: { full_name: 'Nome Atualizado' } }
        customer.reload
        expect(customer.full_name).to eq('Nome Atualizado')
      end

      it 'redirects to customers list' do
        patch customer_path(customer), params: { customer: { full_name: 'Nome Atualizado' } }
        expect(response).to redirect_to(customers_path)
      end
    end

    context 'with guarantor' do
      it 'creates a new guarantor' do
        guarantor_params = {
          full_name: 'Novo Fiador',
          cpf: CPF.generate,
          phone: '11777776666'
        }

        expect {
          patch customer_path(customer), params: { customer: { full_name: customer.full_name }, guarantor: guarantor_params }
        }.to change(Guarantor, :count).by(1)
      end

      it 'updates existing guarantor' do
        guarantor = create(:guarantor)
        customer.update(guarantor: guarantor)

        patch customer_path(customer), params: {
          customer: { full_name: customer.full_name },
          guarantor: { id: guarantor.id, full_name: 'Fiador Atualizado', cpf: guarantor.cpf, phone: guarantor.phone }
        }

        guarantor.reload
        expect(guarantor.full_name).to eq('Fiador Atualizado')
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch customer_path(customer), params: { customer: { full_name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch customer_path(customer), params: { customer: { full_name: 'Nome' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /customers/:id' do
    let!(:customer) { create(:customer) }

    it 'destroys the customer' do
      expect {
        delete customer_path(customer)
      }.to change(Customer, :count).by(-1)
    end

    it 'redirects to customers list' do
      delete customer_path(customer)
      expect(response).to redirect_to(customers_path)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete customer_path(customer)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
