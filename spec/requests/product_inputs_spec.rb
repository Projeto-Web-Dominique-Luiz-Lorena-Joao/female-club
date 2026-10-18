# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ProductInputs', type: :request do
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:supplier) { create(:supplier) }

  before { login_as(user, scope: :user) }

  describe 'GET /product_inputs' do
    before do
      create_list(:product_input, 3, product: product, supplier: supplier)
    end

    it 'returns success' do
      get product_inputs_path
      expect(response).to have_http_status(:success)
    end

    context 'with product_id filter' do
      it 'filters by product' do
        get product_inputs_path, params: { product_id: product.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with supplier_id filter' do
      it 'filters by supplier' do
        get product_inputs_path, params: { supplier_id: supplier.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with date range filter' do
      it 'filters by date range' do
        get product_inputs_path, params: { start_date: 1.week.ago.to_date, end_date: Date.today }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get product_inputs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_inputs/:id' do
    let(:product_input) { create(:product_input, product: product, supplier: supplier) }

    it 'returns success' do
      get product_input_path(product_input)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get product_input_path(product_input)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_inputs/new' do
    it 'returns success' do
      get new_product_input_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_product_input_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /product_inputs' do
    let(:valid_attributes) do
      {
        product_id: product.id,
        supplier_id: supplier.id,
        quantity: 10,
        unit_cost: '15,00',
        date_input: Date.today
      }
    end

    context 'with valid parameters' do
      it 'creates a new product input' do
        expect {
          post product_inputs_path, params: { product_input: valid_attributes }
        }.to change(ProductInput, :count).by(1)
      end

      it 'redirects to product inputs list' do
        post product_inputs_path, params: { product_input: valid_attributes }
        expect(response).to redirect_to(product_inputs_path)
      end
    end

    context 'with date and time parameters' do
      it 'combines date and time into date_input' do
        attributes = valid_attributes.merge(
          date_input: '2026-01-15',
          date_input_time: '09:30'
        )
        post product_inputs_path, params: { product_input: attributes }
        expect(response).to redirect_to(product_inputs_path)
        input = ProductInput.last
        expect(input.date_input.hour).to eq(9)
        expect(input.date_input.min).to eq(30)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(quantity: nil) }

      it 'does not create a new product input' do
        expect {
          post product_inputs_path, params: { product_input: invalid_attributes }
        }.not_to change(ProductInput, :count)
      end

      it 'returns unprocessable_entity' do
        post product_inputs_path, params: { product_input: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post product_inputs_path, params: { product_input: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_inputs/:id/edit' do
    let(:product_input) { create(:product_input, product: product, supplier: supplier) }

    it 'returns success' do
      get edit_product_input_path(product_input)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_product_input_path(product_input)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /product_inputs/:id' do
    let(:product_input) { create(:product_input, product: product, supplier: supplier, quantity: 10) }

    context 'with valid parameters' do
      it 'updates the product input' do
        patch product_input_path(product_input), params: { product_input: { quantity: 20 } }
        product_input.reload
        expect(product_input.quantity).to eq(20)
      end

      it 'redirects to the product input' do
        patch product_input_path(product_input), params: { product_input: { quantity: 20 } }
        expect(response).to redirect_to(product_input)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch product_input_path(product_input), params: { product_input: { quantity: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch product_input_path(product_input), params: { product_input: { quantity: 20 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /product_inputs/:id' do
    let!(:product_input) { create(:product_input, product: product, supplier: supplier) }

    it 'destroys the product input' do
      expect {
        delete product_input_path(product_input)
      }.to change(ProductInput, :count).by(-1)
    end

    it 'redirects to product inputs list' do
      delete product_input_path(product_input)
      expect(response).to redirect_to(product_inputs_path)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete product_input_path(product_input)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_inputs/search_products' do
    before do
      create(:product, name: 'Shampoo', active: true)
      create(:product, name: 'Condicionador', active: true)
      create(:product, name: 'Produto Inativo', active: false)
    end

    it 'returns matching products as JSON' do
      get search_products_product_inputs_path, params: { query: 'Shampoo' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Shampoo')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_products_product_inputs_path, params: { query: 'Shampoo' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_inputs/list_products' do
    before do
      create_list(:product, 3, active: true)
    end

    it 'returns all active products as JSON' do
      get list_products_product_inputs_path
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to be >= 3
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get list_products_product_inputs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_inputs/search_suppliers' do
    before do
      create(:supplier, legal_name: 'Fornecedor ABC', status: 'ativo')
      create(:supplier, legal_name: 'Fornecedor XYZ', status: 'inativo')
    end

    it 'returns matching suppliers as JSON' do
      get search_suppliers_product_inputs_path, params: { query: 'ABC' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Fornecedor ABC')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_suppliers_product_inputs_path, params: { query: 'ABC' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_inputs/list_suppliers' do
    before do
      create_list(:supplier, 3, status: 'ativo')
    end

    it 'returns all active suppliers as JSON' do
      get list_suppliers_product_inputs_path
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to be >= 3
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get list_suppliers_product_inputs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
