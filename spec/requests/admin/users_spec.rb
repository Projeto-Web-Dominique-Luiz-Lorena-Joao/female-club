# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Users', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe 'GET /admin/users' do
    context 'as admin' do
      before { login_as(admin, scope: :user) }

      it 'returns success' do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it 'displays the page title' do
        get admin_users_path
        expect(response.body).to include('Usuários do Sistema')
      end

      it 'lists users' do
        regular_user
        get admin_users_path
        expect(response.body).to include(regular_user.email)
      end

      it 'filters active users' do
        regular_user
        inactive = create(:user, active: false)
        get admin_users_path(status: 'active')
        expect(response.body).to include(regular_user.email)
        expect(response.body).not_to include(inactive.email)
      end

      it 'filters inactive users' do
        regular_user
        inactive = create(:user, active: false)
        get admin_users_path(status: 'false')
        expect(response.body).not_to include(regular_user.email)
        expect(response.body).to include(inactive.email)
      end

      it 'shows user statistics' do
        regular_user
        get admin_users_path
        expect(response.body).to include('Total')
        expect(response.body).to include('Ativos')
        expect(response.body).to include('Cancelados')
      end
    end

    context 'as regular user' do
      before { login_as(regular_user, scope: :user) }

      it 'redirects to dashboard' do
        get admin_users_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'without authentication' do
      it 'redirects to login' do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /admin/users/:id/deactivate' do
    before { login_as(admin, scope: :user) }

    it 'deactivates a regular user' do
      patch deactivate_admin_user_path(regular_user)
      expect(regular_user.reload.active).to be false
    end

    it 'redirects with success message' do
      patch deactivate_admin_user_path(regular_user)
      expect(response).to redirect_to(admin_users_path)
      follow_redirect!
      expect(response.body).to include('cancelada com sucesso')
    end

    it 'prevents deactivating self' do
      patch deactivate_admin_user_path(admin)
      expect(admin.reload.active).to be true
      expect(response).to redirect_to(admin_users_path)
    end

    it 'prevents deactivating another admin' do
      other_admin = create(:user, admin: true)
      patch deactivate_admin_user_path(other_admin)
      expect(other_admin.reload.active).to be true
    end

    context 'as regular user' do
      before { login_as(regular_user, scope: :user) }

      it 'redirects to dashboard' do
        other = create(:user)
        patch deactivate_admin_user_path(other)
        expect(response).to redirect_to(dashboard_path)
        expect(other.reload.active).to be true
      end
    end
  end

  describe 'PATCH /admin/users/:id/reactivate' do
    before { login_as(admin, scope: :user) }

    let(:inactive_user) { create(:user, active: false) }

    it 'reactivates a user' do
      patch reactivate_admin_user_path(inactive_user)
      expect(inactive_user.reload.active).to be true
    end

    it 'redirects with success message' do
      patch reactivate_admin_user_path(inactive_user)
      expect(response).to redirect_to(admin_users_path)
      follow_redirect!
      expect(response.body).to include('reativada com sucesso')
    end

    context 'as regular user' do
      before { login_as(regular_user, scope: :user) }

      it 'redirects to dashboard' do
        patch reactivate_admin_user_path(inactive_user)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
