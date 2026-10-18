# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ProductOutputs', type: :request do
  let(:user) { create(:user) }
  let(:product) { create(:product, :with_stock, initial_stock: 100) }

  before { login_as(user, scope: :user) }

  describe 'GET /product_outputs' do
    before do
      create_list(:product_output, 3, product: product)
    end

    it 'returns success' do
      get product_outputs_path
      expect(response).to have_http_status(:success)
    end

    context 'with product_id filter' do
      it 'filters by product' do
        get product_outputs_path, params: { product_id: product.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with output_type filter' do
      it 'filters by output type' do
        get product_outputs_path, params: { output_type: 'venda' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with date range filter' do
      it 'filters by date range' do
        get product_outputs_path, params: { start_date: 1.week.ago.to_date, end_date: Date.today }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get product_outputs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_outputs/:id' do
    let(:product_output) { create(:product_output, product: product) }

    it 'returns success' do
      get product_output_path(product_output)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get product_output_path(product_output)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_outputs/new' do
    it 'returns success' do
      get new_product_output_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_product_output_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /product_outputs' do
    let(:valid_attributes) do
      {
        product_id: product.id,
        quantity: 5,
        output_type: 'venda',
        date_output: Date.today
      }
    end

    context 'with valid parameters' do
      it 'creates a new product output' do
        expect {
          post product_outputs_path, params: { product_output: valid_attributes }
        }.to change(ProductOutput, :count).by(1)
      end

      it 'redirects to product outputs list' do
        post product_outputs_path, params: { product_output: valid_attributes }
        expect(response).to redirect_to(product_outputs_path)
      end
    end

    context 'with date and time parameters' do
      it 'combines date and time into date_output' do
        attributes = valid_attributes.merge(
          date_output: '2026-01-15',
          date_output_time: '14:30'
        )
        post product_outputs_path, params: { product_output: attributes }
        expect(response).to redirect_to(product_outputs_path)
        output = ProductOutput.last
        expect(output.date_output.hour).to eq(14)
        expect(output.date_output.min).to eq(30)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(quantity: nil) }

      it 'does not create a new product output' do
        expect {
          post product_outputs_path, params: { product_output: invalid_attributes }
        }.not_to change(ProductOutput, :count)
      end

      it 'returns unprocessable_entity' do
        post product_outputs_path, params: { product_output: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post product_outputs_path, params: { product_output: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_outputs/:id/edit' do
    let(:product_output) { create(:product_output, product: product) }

    it 'returns success' do
      get edit_product_output_path(product_output)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_product_output_path(product_output)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /product_outputs/:id' do
    let(:product_output) { create(:product_output, product: product, quantity: 5) }

    context 'with valid parameters' do
      it 'updates the product output' do
        patch product_output_path(product_output), params: { product_output: { quantity: 10 } }
        product_output.reload
        expect(product_output.quantity).to eq(10)
      end

      it 'redirects to the product output' do
        patch product_output_path(product_output), params: { product_output: { quantity: 10 } }
        expect(response).to redirect_to(product_output)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch product_output_path(product_output), params: { product_output: { quantity: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch product_output_path(product_output), params: { product_output: { quantity: 10 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /product_outputs/:id' do
    let!(:product_output) { create(:product_output, product: product) }

    it 'destroys the product output' do
      expect {
        delete product_output_path(product_output)
      }.to change(ProductOutput, :count).by(-1)
    end

    it 'redirects to product outputs list' do
      delete product_output_path(product_output)
      expect(response).to redirect_to(product_outputs_path)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete product_output_path(product_output)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_outputs/search_products' do
    before do
      create(:product, name: 'Shampoo', active: true)
      create(:product, name: 'Condicionador', active: true)
    end

    it 'returns matching products as JSON' do
      get search_products_product_outputs_path, params: { query: 'Shampoo' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('Shampoo')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get search_products_product_outputs_path, params: { query: 'Shampoo' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /product_outputs/list_products' do
    before do
      create_list(:product, 3, active: true)
    end

    it 'returns all active products as JSON' do
      get list_products_product_outputs_path
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to be >= 3
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get list_products_product_outputs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
