# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Suppliers', type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'GET /suppliers' do
    before do
      create_list(:supplier, 3)
    end

    it 'returns success' do
      get suppliers_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the suppliers list' do
      get suppliers_path
      expect(response.body).to include('Fornecedor')
    end

    context 'with category filter' do
      before do
        create(:supplier, product_category: 'cosmeticos')
        create(:supplier, product_category: 'cabelo')
      end

      it 'filters by category' do
        get suppliers_path, params: { category: 'cosmeticos' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with status filter' do
      before do
        create(:supplier, active: true)
        create(:supplier, active: false)
      end

      it 'filters by active status' do
        get suppliers_path, params: { status: 'ativo' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by inactive status' do
        get suppliers_path, params: { status: 'inativo' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with search' do
      before do
        create(:supplier, legal_name: 'Empresa Fornecedora ABC')
        create(:supplier, trade_name: 'Distribuidora XYZ')
      end

      it 'searches by legal name' do
        get suppliers_path, params: { search: 'ABC' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by trade name' do
        get suppliers_path, params: { search: 'XYZ' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by phone digits' do
        create(:supplier, phone_number: '11999887766')
        get suppliers_path, params: { search: '999887' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get suppliers_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /suppliers/:id' do
    let(:supplier) { create(:supplier) }

    it 'returns success' do
      get supplier_path(supplier)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get supplier_path(supplier)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /suppliers/new' do
    it 'returns success' do
      get new_supplier_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_supplier_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /suppliers' do
    let(:valid_attributes) do
      {
        legal_name: 'Empresa Teste LTDA',
        trade_name: 'Empresa Teste',
        phone_number: '11999998888',
        product_category: 'cosmeticos'
      }
    end

    context 'with valid parameters' do
      it 'creates a new supplier' do
        expect {
          post suppliers_path, params: { supplier: valid_attributes }
        }.to change(Supplier, :count).by(1)
      end

      it 'redirects to suppliers list' do
        post suppliers_path, params: { supplier: valid_attributes }
        expect(response).to redirect_to(suppliers_path)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(legal_name: '') }

      it 'does not create a new supplier' do
        expect {
          post suppliers_path, params: { supplier: invalid_attributes }
        }.not_to change(Supplier, :count)
      end

      it 'returns unprocessable_entity' do
        post suppliers_path, params: { supplier: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post suppliers_path, params: { supplier: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /suppliers/:id/edit' do
    let(:supplier) { create(:supplier) }

    it 'returns success' do
      get edit_supplier_path(supplier)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_supplier_path(supplier)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /suppliers/:id' do
    let(:supplier) { create(:supplier, legal_name: 'Nome Original') }

    context 'with valid parameters' do
      it 'updates the supplier' do
        patch supplier_path(supplier), params: { supplier: { legal_name: 'Nome Atualizado' } }
        supplier.reload
        expect(supplier.legal_name).to eq('Nome Atualizado')
      end

      it 'redirects to suppliers list' do
        patch supplier_path(supplier), params: { supplier: { legal_name: 'Nome Atualizado' } }
        expect(response).to redirect_to(suppliers_path)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch supplier_path(supplier), params: { supplier: { legal_name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch supplier_path(supplier), params: { supplier: { legal_name: 'Nome' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /suppliers/:id' do
    let!(:supplier) { create(:supplier, active: true) }

    it 'inactivates the supplier instead of destroying' do
      expect {
        delete supplier_path(supplier)
      }.not_to change(Supplier, :count)

      supplier.reload
      expect(supplier.active).to be false
    end

    it 'redirects to suppliers list' do
      delete supplier_path(supplier)
      expect(response).to redirect_to(suppliers_path)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete supplier_path(supplier)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /suppliers/:id/reactivate' do
    let(:inactive_supplier) { create(:supplier, active: false) }

    it 'reactivates the supplier' do
      patch reactivate_supplier_path(inactive_supplier)
      inactive_supplier.reload
      expect(inactive_supplier.active).to be true
    end

    it 'redirects to the supplier' do
      patch reactivate_supplier_path(inactive_supplier)
      expect(response).to redirect_to(inactive_supplier)
    end

    context 'when reactivation fails' do
      it 'shows an error message' do
        allow_any_instance_of(Supplier).to receive(:update).and_return(false)
        patch reactivate_supplier_path(inactive_supplier)
        expect(flash[:alert]).to include('Não foi possível reativar')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch reactivate_supplier_path(inactive_supplier)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
