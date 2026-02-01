# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  describe 'GET /users/sign_up' do
    it 'returns success' do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the registration form' do
      get new_user_registration_path
      expect(response.body).to include('email')
      expect(response.body).to include('password')
    end
  end

  describe 'POST /users' do
    context 'with valid attributes' do
      let(:valid_attributes) do
        {
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          items_per_page: 25
        }
      end

      it 'creates a new user' do
        expect {
          post user_registration_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'redirects to dashboard' do
        post user_registration_path, params: { user: valid_attributes }
        expect(response).to redirect_to(authenticated_root_path)
      end

      it 'sets items_per_page' do
        post user_registration_path, params: { user: valid_attributes }
        expect(User.last.items_per_page).to eq(25)
      end
    end

    context 'with invalid attributes' do
      it 'returns unprocessable entity with missing email' do
        post user_registration_path, params: {
          user: { email: '', password: 'password123', password_confirmation: 'password123' }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns unprocessable entity with short password' do
        post user_registration_path, params: {
          user: { email: 'test@example.com', password: '123', password_confirmation: '123' }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns unprocessable entity with mismatched passwords' do
        post user_registration_path, params: {
          user: { email: 'test@example.com', password: 'password123', password_confirmation: 'different' }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns unprocessable entity with duplicate email' do
        create(:user, email: 'existing@example.com')
        post user_registration_path, params: {
          user: { email: 'existing@example.com', password: 'password123', password_confirmation: 'password123' }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
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
    let(:user) { create(:user) }  # Uses default password "Password123"

    before { login_as(user, scope: :user) }

    context 'with valid attributes' do
      it 'updates items_per_page' do
        patch user_registration_path, params: {
          user: {
            items_per_page: 50,
            current_password: 'Password123'
          }
        }

        expect(response).to redirect_to(root_path)
        user.reload
        expect(user.items_per_page).to eq(50)
      end

      it 'updates password' do
        patch user_registration_path, params: {
          user: {
            password: 'newpassword123',
            password_confirmation: 'newpassword123',
            current_password: 'Password123'
          }
        }

        expect(response).to redirect_to(root_path)
        user.reload
        expect(user.valid_password?('newpassword123')).to be true
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

  describe 'GET /users/cancel' do
    let(:user) { create(:user) }

    before { login_as(user, scope: :user) }

    it 'redirects back or to root' do
      get cancel_user_registration_path
      expect(response).to redirect_to(root_path)
    end
  end
end
