# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AccessRequests', type: :request do
  describe 'GET /access_requests/new' do
    it 'returns success' do
      get new_access_request_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the request form' do
      get new_access_request_path
      expect(response.body).to include('Solicitar Acesso')
      expect(response.body).to include('E-mail')
      expect(response.body).to include('Senha')
      expect(response.body).to include('Mensagem')
    end

    it 'does not require authentication' do
      get new_access_request_path
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end

  describe 'POST /access_requests' do
    context 'with valid attributes' do
      let(:valid_params) do
        {
          access_request: {
            email: 'nova@usuario.com',
            password: 'Password123!',
            password_confirmation: 'Password123!',
            message: 'Preciso de acesso para vendas'
          }
        }
      end

      it 'creates an access request' do
        expect {
          post access_requests_path, params: valid_params
        }.to change(AccessRequest, :count).by(1)
      end

      it 'redirects to login with success message' do
        post access_requests_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(response.body).to include('Solicitação enviada com sucesso')
      end

      it 'stores encrypted password' do
        post access_requests_path, params: valid_params
        request = AccessRequest.last
        expect(request.encrypted_password).to be_present
        expect(request.encrypted_password).not_to eq('Password123!')
      end

      it 'sets status as pending' do
        post access_requests_path, params: valid_params
        expect(AccessRequest.last.status).to eq('pending')
      end
    end

    context 'with invalid attributes' do
      it 'returns unprocessable entity with missing email' do
        post access_requests_path, params: {
          access_request: { email: '', password: 'Password123!', password_confirmation: 'Password123!' }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns unprocessable entity with weak password' do
        post access_requests_path, params: {
          access_request: { email: 'test@test.com', password: 'abc', password_confirmation: 'abc' }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns unprocessable entity with mismatched passwords' do
        post access_requests_path, params: {
          access_request: { email: 'test@test.com', password: 'Password123!', password_confirmation: 'Different1!' }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
