# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::AccessRequests', type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'GET /admin/access_requests' do
    it 'returns success' do
      get admin_access_requests_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the page title' do
      get admin_access_requests_path
      expect(response.body).to include('Solicitações de Acesso')
    end

    context 'with access requests' do
      let!(:pending_request) { create(:access_request, email: 'pending@test.com') }
      let!(:approved_request) { create(:access_request, :approved, email: 'approved@test.com') }

      it 'displays all requests' do
        get admin_access_requests_path
        expect(response.body).to include('pending@test.com')
        expect(response.body).to include('approved@test.com')
      end

      it 'filters by status' do
        get admin_access_requests_path(status: 'pending')
        expect(response.body).to include('pending@test.com')
        expect(response.body).not_to include('approved@test.com')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get admin_access_requests_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /admin/access_requests/:id/approve' do
    let!(:access_request) { create(:access_request, email: 'novo@user.com') }

    it 'creates a new user' do
      expect {
        patch approve_admin_access_request_path(access_request)
      }.to change(User, :count).by(1)
    end

    it 'creates user with correct email' do
      patch approve_admin_access_request_path(access_request)
      expect(User.find_by(email: 'novo@user.com')).to be_present
    end

    it 'marks request as approved' do
      patch approve_admin_access_request_path(access_request)
      expect(access_request.reload.status).to eq('approved')
    end

    it 'redirects with success message' do
      patch approve_admin_access_request_path(access_request)
      expect(response).to redirect_to(admin_access_requests_path)
      follow_redirect!
      expect(response.body).to include('aprovada')
    end

    it 'allows the new user to login with the requested password' do
      patch approve_admin_access_request_path(access_request)
      new_user = User.find_by(email: 'novo@user.com')
      expect(new_user.valid_password?('Password123!')).to be true
    end

    context 'when email already exists' do
      before { create(:user, email: 'novo@user.com') }

      it 'does not create a duplicate user' do
        expect {
          patch approve_admin_access_request_path(access_request)
        }.not_to change(User, :count)
      end

      it 'redirects with alert' do
        patch approve_admin_access_request_path(access_request)
        expect(response).to redirect_to(admin_access_requests_path)
        follow_redirect!
        expect(response.body).to include('Já existe')
      end
    end
  end

  describe 'PATCH /admin/access_requests/:id/reject' do
    let!(:access_request) { create(:access_request) }

    it 'marks request as rejected' do
      patch reject_admin_access_request_path(access_request)
      expect(access_request.reload.status).to eq('rejected')
    end

    it 'does not create a user' do
      expect {
        patch reject_admin_access_request_path(access_request)
      }.not_to change(User, :count)
    end

    it 'redirects with message' do
      patch reject_admin_access_request_path(access_request)
      expect(response).to redirect_to(admin_access_requests_path)
      follow_redirect!
      expect(response.body).to include('rejeitada')
    end
  end
end
