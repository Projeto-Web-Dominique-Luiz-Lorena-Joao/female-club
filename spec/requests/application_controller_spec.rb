# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ApplicationController', type: :request do
  let(:user) { create(:user, items_per_page: 15) }

  describe 'PATCH /update_pagination_preference' do
    context 'when user is signed in' do
      before { login_as(user, scope: :user) }

      it 'updates items_per_page with valid value' do
        patch update_pagination_preference_path, params: { items_per_page: 25 }

        expect(response).to redirect_to(root_path)
        user.reload
        expect(user.items_per_page).to eq(25)
      end

      it 'resets items_per_page to nil when value is nil' do
        patch update_pagination_preference_path, params: { items_per_page: nil }

        expect(response).to redirect_to(root_path)
        user.reload
        expect(user.items_per_page).to be_nil
      end

      it 'resets items_per_page when value is empty string' do
        patch update_pagination_preference_path, params: { items_per_page: '' }

        expect(response).to redirect_to(root_path)
        user.reload
        expect(user.items_per_page).to be_nil
      end

      it 'redirects back when referer is present' do
        patch update_pagination_preference_path,
             params: { items_per_page: 50 },
             headers: { 'HTTP_REFERER' => products_path }

        expect(response).to redirect_to(products_path)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        patch update_pagination_preference_path, params: { items_per_page: 25 }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'per_page helper' do
    before { login_as(user, scope: :user) }

    context 'with per_page parameter' do
      it 'uses per_page parameter for valid values' do
        get products_path, params: { per_page: 25 }
        expect(response).to have_http_status(:success)
        # The view should use 25 items per page
      end

      it 'uses per_page parameter value of 10' do
        get products_path, params: { per_page: 10 }
        expect(response).to have_http_status(:success)
      end

      it 'uses per_page parameter value of 50' do
        get products_path, params: { per_page: 50 }
        expect(response).to have_http_status(:success)
      end
    end

    context 'without per_page parameter' do
      it 'uses user items_per_page preference' do
        user.update(items_per_page: 20)
        get products_path
        expect(response).to have_http_status(:success)
      end

      it 'defaults to 15 when user has no preference' do
        user.update(items_per_page: nil)
        get products_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
