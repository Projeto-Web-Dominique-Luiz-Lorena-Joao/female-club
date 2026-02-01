# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Services', type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe 'GET /services' do
    before do
      create_list(:service, 3, active: 'ativo')
    end

    it 'returns success' do
      get services_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the services list' do
      get services_path
      expect(response.body).to include('Serviço')
    end

    context 'with active filter' do
      before do
        create(:service, active: 'ativo')
        create(:service, active: 'inativo')
      end

      it 'filters by active status' do
        get services_path, params: { active: 'ativo' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by inactive status' do
        get services_path, params: { active: 'inativo' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get services_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /services/:id' do
    let(:service) { create(:service) }

    it 'returns success' do
      get service_path(service)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get service_path(service)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /services/new' do
    it 'returns success' do
      get new_service_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_service_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /services' do
    let(:valid_attributes) do
      {
        name: 'Corte de Cabelo',
        description: 'Corte feminino',
        price: 50.00,
        active: 'ativo'
      }
    end

    context 'with valid parameters' do
      it 'creates a new service' do
        expect {
          post services_path, params: { service: valid_attributes }
        }.to change(Service, :count).by(1)
      end

      it 'redirects to the created service' do
        post services_path, params: { service: valid_attributes }
        expect(response).to redirect_to(Service.last)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { valid_attributes.merge(name: '') }

      it 'does not create a new service' do
        expect {
          post services_path, params: { service: invalid_attributes }
        }.not_to change(Service, :count)
      end

      it 'returns unprocessable_entity' do
        post services_path, params: { service: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post services_path, params: { service: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /services/:id/edit' do
    let(:service) { create(:service) }

    it 'returns success' do
      get edit_service_path(service)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_service_path(service)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /services/:id' do
    let(:service) { create(:service, name: 'Nome Original') }

    context 'with valid parameters' do
      it 'updates the service' do
        patch service_path(service), params: { service: { name: 'Nome Atualizado' } }
        service.reload
        expect(service.name).to eq('Nome Atualizado')
      end

      it 'redirects to the service' do
        patch service_path(service), params: { service: { name: 'Nome Atualizado' } }
        expect(response).to redirect_to(service)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch service_path(service), params: { service: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch service_path(service), params: { service: { name: 'Nome' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /services/:id' do
    let!(:service) { create(:service) }

    it 'destroys the service' do
      expect {
        delete service_path(service)
      }.to change(Service, :count).by(-1)
    end

    it 'redirects to services list' do
      delete service_path(service)
      expect(response).to redirect_to(services_path)
    end

    context 'when destroy fails' do
      it 'shows an error message' do
        allow_any_instance_of(Service).to receive(:destroy).and_return(false)
        delete service_path(service)
        expect(flash[:alert]).to include('Erro ao excluir serviço')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete service_path(service)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /services/:id/change_status' do
    let(:service) { create(:service, active: 'ativo') }

    it 'changes the service status' do
      patch change_status_service_path(service), params: { new_active: 'inativo' }
      service.reload
      expect(service.active).to eq('inativo')
    end

    it 'redirects to services list' do
      patch change_status_service_path(service), params: { new_active: 'inativo' }
      expect(response).to redirect_to(services_path)
    end

    context 'with invalid status' do
      it 'redirects with error' do
        patch change_status_service_path(service), params: { new_active: 'invalid_status' }
        expect(response).to redirect_to(services_path)
        expect(flash[:alert]).to eq('Erro ao atualizar status.')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch change_status_service_path(service), params: { new_active: 'inativo' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
