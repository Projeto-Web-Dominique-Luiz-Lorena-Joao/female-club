# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'InventoryStatus', type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'GET /inventory_status' do
    before do
      create(:product, name: 'Produto A', stock_status: 'em_estoque', active: true)
      create(:product, name: 'Produto B', stock_status: 'baixo', active: true)
      create(:product, name: 'Produto C', stock_status: 'critico', active: true)
      create(:product, name: 'Produto Inativo', active: false)
    end

    it 'returns success' do
      get inventory_status_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the inventory status' do
      get inventory_status_path
      expect(response.body).to include('Estoque')
    end

    context 'with stock_status filter' do
      it 'filters by stock status' do
        get inventory_status_path, params: { stock_status: 'critico' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by low stock' do
        get inventory_status_path, params: { stock_status: 'baixo' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with search' do
      it 'searches by product name' do
        get inventory_status_path, params: { search: 'Produto A' }
        expect(response).to have_http_status(:success)
      end

      it 'searches by product code' do
        create(:product, code: 'ABC123', active: true)
        get inventory_status_path, params: { search: 'ABC123' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get inventory_status_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
