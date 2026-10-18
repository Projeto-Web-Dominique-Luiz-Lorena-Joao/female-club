# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Suppliers', type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'GET /api/suppliers/search' do
    before do
      create(:supplier, legal_name: 'Empresa Alpha Ltda', trade_name: 'Alpha Cosméticos')
      create(:supplier, legal_name: 'Empresa Beta SA', trade_name: 'Beta Beauty')
      create(:supplier, legal_name: 'Gamma Comercio', trade_name: 'Gamma Store')
    end

    it 'returns suppliers matching legal_name' do
      get api_suppliers_search_path, params: { q: 'Alpha' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to include('Alpha')
    end

    it 'returns suppliers matching trade_name' do
      get api_suppliers_search_path, params: { q: 'Beauty' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
    end

    it 'returns empty array when no match' do
      get api_suppliers_search_path, params: { q: 'Nonexistent' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_empty
    end

    it 'limits results to 10' do
      12.times { |i| create(:supplier, legal_name: "Test Supplier #{i}") }

      get api_suppliers_search_path, params: { q: 'Test' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(10)
    end

    it 'returns suppliers ordered by legal_name' do
      get api_suppliers_search_path, params: { q: 'Empresa' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      names = json.map { |e| e['name'] }
      expect(names).to eq(names.sort)
    end

    it 'returns id and name for each supplier' do
      get api_suppliers_search_path, params: { q: 'Alpha' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.first).to have_key('id')
      expect(json.first).to have_key('name')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get api_suppliers_search_path, params: { q: 'Alpha' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
