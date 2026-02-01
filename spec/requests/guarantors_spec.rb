# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Guarantors', type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'GET /guarantors' do
    before do
      create_list(:guarantor, 3)
    end

    it 'returns success' do
      get guarantors_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the guarantors list' do
      get guarantors_path
      expect(response.body).to include('Fiador')
    end

    context 'with search' do
      before do
        create(:guarantor, full_name: 'João Fiador')
        create(:guarantor, full_name: 'Maria Fiadora')
      end

      it 'searches by name' do
        get guarantors_path, params: { search: 'João' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by CPF digits' do
        guarantor = create(:guarantor)
        get guarantors_path, params: { search: guarantor.cpf[0..5] }
        expect(response).to have_http_status(:success)
      end

      it 'searches by phone digits' do
        create(:guarantor, phone: '11999887766')
        get guarantors_path, params: { search: '999887' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by associated customer name' do
        customer = create(:customer, full_name: 'Cliente Associado')
        guarantor = create(:guarantor)
        customer.update(guarantor: guarantor)
        get guarantors_path, params: { search: 'Cliente Associado' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with status filter' do
      before do
        create(:guarantor, status: 'ativo')
        create(:guarantor, status: 'inativo')
      end

      it 'filters by status' do
        get guarantors_path, params: { status: 'ativo' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get guarantors_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /guarantors/:id' do
    let(:guarantor) { create(:guarantor) }

    it 'returns success' do
      get guarantor_path(guarantor)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get guarantor_path(guarantor)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /guarantors/new' do
    it 'returns success' do
      get new_guarantor_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_guarantor_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /guarantors' do
    let(:valid_attributes) do
      {
        full_name: 'Fiador Teste',
        cpf: CPF.generate,
        phone: '11999998888',
        relationship: 'pai'
      }
    end

    context 'with valid parameters' do
      it 'creates a new guarantor' do
        expect {
          post guarantors_path, params: { guarantor: valid_attributes }
        }.to change(Guarantor, :count).by(1)
      end

      it 'redirects to the created guarantor' do
        post guarantors_path, params: { guarantor: valid_attributes }
        expect(response).to redirect_to(Guarantor.last)
      end
    end

    context 'with customer association' do
      let(:customer) { create(:customer) }

      it 'creates a guarantor and associates to customer' do
        expect {
          post guarantors_path, params: { guarantor: valid_attributes, customer_association_id: customer.id }
        }.to change(Guarantor, :count).by(1)

        customer.reload
        expect(customer.guarantor).to eq(Guarantor.last)
      end
    end

    context 'with invalid customer association' do
      it 'does not create guarantor when customer not found' do
        post guarantors_path, params: { guarantor: valid_attributes, customer_association_id: 999999 }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(full_name: '') }

      it 'does not create a new guarantor' do
        expect {
          post guarantors_path, params: { guarantor: invalid_attributes }
        }.not_to change(Guarantor, :count)
      end

      it 'returns unprocessable_entity' do
        post guarantors_path, params: { guarantor: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post guarantors_path, params: { guarantor: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /guarantors/:id/edit' do
    let(:guarantor) { create(:guarantor) }

    it 'returns success' do
      get edit_guarantor_path(guarantor)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_guarantor_path(guarantor)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /guarantors/:id' do
    let(:guarantor) { create(:guarantor, full_name: 'Nome Original') }

    context 'with valid parameters' do
      it 'updates the guarantor' do
        patch guarantor_path(guarantor), params: { guarantor: { full_name: 'Nome Atualizado' } }
        guarantor.reload
        expect(guarantor.full_name).to eq('Nome Atualizado')
      end

      it 'redirects to guarantors list' do
        patch guarantor_path(guarantor), params: { guarantor: { full_name: 'Nome Atualizado' } }
        expect(response).to redirect_to(guarantors_path)
      end
    end

    context 'with customer association' do
      let(:customer) { create(:customer) }

      it 'associates the guarantor to a customer' do
        patch guarantor_path(guarantor), params: {
          guarantor: { full_name: guarantor.full_name },
          customer_association_id: customer.id
        }
        customer.reload
        expect(customer.guarantor).to eq(guarantor)
      end

      context 'when customer already has another guarantor' do
        let(:other_guarantor) { create(:guarantor) }

        before { customer.update(guarantor: other_guarantor) }

        it 'redirects to edit with error' do
          patch guarantor_path(guarantor), params: {
            guarantor: { full_name: guarantor.full_name },
            customer_association_id: customer.id
          }
          expect(response).to redirect_to(edit_guarantor_path(guarantor))
          expect(flash[:alert]).to include('já possui um fiador')
        end
      end

      context 'when guarantor is already associated to another customer' do
        let(:other_customer) { create(:customer) }

        before { other_customer.update(guarantor: guarantor) }

        it 'removes association from previous customer and associates to new one' do
          patch guarantor_path(guarantor), params: {
            guarantor: { full_name: guarantor.full_name },
            customer_association_id: customer.id
          }
          expect(response).to redirect_to(guarantors_path)
          other_customer.reload
          customer.reload
          expect(other_customer.guarantor).to be_nil
          expect(customer.guarantor).to eq(guarantor)
        end
      end

      context 'when customer not found on update' do
        it 'redirects to edit with error' do
          patch guarantor_path(guarantor), params: {
            guarantor: { full_name: guarantor.full_name },
            customer_association_id: 999999
          }
          expect(response).to redirect_to(edit_guarantor_path(guarantor))
          expect(flash[:alert]).to include('Cliente não encontrado')
        end
      end
    end

    context 'removing customer association' do
      let(:customer) { create(:customer) }

      before { customer.update(guarantor: guarantor) }

      it 'removes the association when empty string is passed' do
        patch guarantor_path(guarantor), params: {
          guarantor: { full_name: guarantor.full_name },
          customer_association_id: ''
        }
        customer.reload
        expect(customer.guarantor).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch guarantor_path(guarantor), params: { guarantor: { full_name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch guarantor_path(guarantor), params: { guarantor: { full_name: 'Nome' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /guarantors/:id' do
    let!(:guarantor) { create(:guarantor) }

    it 'destroys the guarantor' do
      expect {
        delete guarantor_path(guarantor)
      }.to change(Guarantor, :count).by(-1)
    end

    it 'redirects to guarantors list' do
      delete guarantor_path(guarantor)
      expect(response).to redirect_to(guarantors_path)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete guarantor_path(guarantor)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /guarantors/search_customers' do
    before do
      create(:customer, full_name: 'Carla Oliveira')
      create(:customer, full_name: 'Paula Souza')
    end

    it 'returns matching customers as JSON' do
      get search_customers_guarantors_path, params: { query: 'Carla' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Carla Oliveira')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_customers_guarantors_path, params: { query: 'Carla' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
