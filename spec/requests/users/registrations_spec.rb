# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  describe 'GET /users/sign_up (bloqueado)' do
    it 'redirects to access request form' do
      get new_user_registration_path
      expect(response).to redirect_to(new_access_request_path)
    end
  end

  describe 'POST /users (bloqueado)' do
    it 'redirects to access request form' do
      post user_registration_path, params: {
        user: { email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!' }
      }
      expect(response).to redirect_to(new_access_request_path)
    end

    it 'does not create a user' do
      expect {
        post user_registration_path, params: {
          user: { email: 'test@example.com', password: 'Password123!', password_confirmation: 'Password123!' }
        }
      }.not_to change(User, :count)
    end
  end

  describe 'GET /users/edit' do
    let(:user) { create(:user) }

    before { login_as(user, scope: :user) }

    it 'returns success' do
      get edit_user_registration_path
      expect(response).to have_http_status(:success)
    end

    it 'displays user email' do
      get edit_user_registration_path
      expect(response.body).to include(user.email)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /users' do
    let(:user) { create(:user) }

    before { login_as(user, scope: :user) }

    context 'with valid attributes' do
      it 'updates items_per_page' do
        patch user_registration_path, params: {
          user: {
            items_per_page: 50,
            current_password: 'Password123!'
          }
        }

        expect(response).to redirect_to(root_path)
        user.reload
        expect(user.items_per_page).to eq(50)
      end

      it 'updates password' do
        patch user_registration_path, params: {
          user: {
            password: 'NewPassword123!',
            password_confirmation: 'NewPassword123!',
            current_password: 'Password123!'
          }
        }

        expect(response).to redirect_to(root_path)
        user.reload
        expect(user.valid_password?('NewPassword123!')).to be true
      end
    end

    context 'with invalid current password' do
      it 'returns unprocessable entity' do
        patch user_registration_path, params: {
          user: {
            items_per_page: 50,
            current_password: 'wrongpassword'
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /users' do
    let(:user) { create(:user) }

    before { login_as(user, scope: :user) }

    it 'destroys the user account' do
      expect {
        delete user_registration_path
      }.to change(User, :count).by(-1)
    end

    it 'redirects to root' do
      delete user_registration_path
      expect(response).to redirect_to(root_path)
    end
  end
end
