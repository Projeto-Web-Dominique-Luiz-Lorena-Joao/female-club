# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Employees', type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'GET /api/employees/search' do
    before do
      create(:employee, full_name: 'Maria Silva')
      create(:employee, full_name: 'Maria Santos')
      create(:employee, full_name: 'João Pedro')
    end

    it 'returns employees matching the query' do
      get api_employees_search_path, params: { q: 'Maria' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
      expect(json.map { |e| e['name'] }).to all(include('Maria'))
    end

    it 'returns empty array when no match' do
      get api_employees_search_path, params: { q: 'Nonexistent' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_empty
    end

    it 'limits results to 10' do
      12.times { |i| create(:employee, full_name: "Test Employee #{i}") }

      get api_employees_search_path, params: { q: 'Test' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(10)
    end

    it 'returns employees ordered by name' do
      get api_employees_search_path, params: { q: 'Maria' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      names = json.map { |e| e['name'] }
      expect(names).to eq(names.sort)
    end

    it 'returns id and name for each employee' do
      get api_employees_search_path, params: { q: 'Maria' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.first).to have_key('id')
      expect(json.first).to have_key('name')
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get api_employees_search_path, params: { q: 'Maria' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
