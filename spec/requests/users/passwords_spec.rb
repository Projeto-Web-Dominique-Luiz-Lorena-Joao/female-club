# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  let!(:user) { create(:user, email: 'test@example.com') }

  describe 'GET /users/password/new' do
    it 'returns success' do
      get new_user_password_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the password reset form' do
      get new_user_password_path
      expect(response.body).to include('email')
    end
  end

  describe 'POST /users/password' do
    context 'with valid email' do
      it 'sends reset password instructions' do
        expect {
          post user_password_path, params: { user: { email: user.email } }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'redirects to login page' do
        post user_password_path, params: { user: { email: user.email } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with invalid email' do
      it 'returns unprocessable entity' do
        post user_password_path, params: { user: { email: 'nonexistent@example.com' } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /users/password/edit' do
    context 'with valid reset token' do
      let(:reset_token) do
        user.send_reset_password_instructions
        user.reset_password_token
      end

      it 'returns success' do
        raw_token = user.send_reset_password_instructions
        get edit_user_password_path, params: { reset_password_token: raw_token }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid reset token' do
      it 'still returns success (shows form with error on submit)' do
        get edit_user_password_path, params: { reset_password_token: 'invalid' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /users/password' do
    context 'with valid token and password' do
      it 'resets the password and redirects to dashboard' do
        raw_token = user.send_reset_password_instructions

        patch user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: 'NewPassword123!',
            password_confirmation: 'NewPassword123!'
          }
        }

        expect(response).to redirect_to(authenticated_root_path)
      end

      it 'updates the user password' do
        raw_token = user.send_reset_password_instructions

        patch user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: 'NewPassword123!',
            password_confirmation: 'NewPassword123!'
          }
        }

        user.reload
        expect(user.valid_password?('NewPassword123!')).to be true
      end
    end

    context 'with invalid token' do
      it 'returns unprocessable entity' do
        patch user_password_path, params: {
          user: {
            reset_password_token: 'invalid_token',
            password: 'NewPassword123!',
            password_confirmation: 'NewPassword123!'
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with mismatched passwords' do
      it 'returns unprocessable entity' do
        raw_token = user.send_reset_password_instructions

        patch user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: 'NewPassword123!',
            password_confirmation: 'different_password'
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
