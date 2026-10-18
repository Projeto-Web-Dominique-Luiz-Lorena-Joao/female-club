# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Products', type: :request do
  let(:user) { create(:user) }
  let(:supplier) { create(:supplier) }

  before { login_as(user, scope: :user) }

  # ============================================
  # INDEX
  # ============================================
  describe 'GET /products' do
    let!(:product) { create(:product) }

    it 'returns success' do
      get products_path
      expect(response).to have_http_status(:success)
    end

    context 'with filters' do
      let!(:active_product) { create(:product, active: true) }
      let!(:inactive_product) { create(:product, active: false) }
      let!(:beleza_product) { create(:product, category: :beleza_cosmeticos) }
      let!(:low_stock_product) do
        p = create(:product, min_stock: 100)
        create(:product_input, product: p, quantity: 10)
        p.reload.update_stock_status!
        p
      end

      it 'filters by active status' do
        get products_path, params: { active: 'true' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by inactive status' do
        get products_path, params: { active: 'false' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by category' do
        get products_path, params: { category: 'beleza_cosmeticos' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by low stock' do
        get products_path, params: { low_stock: 'true' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by search term' do
        get products_path, params: { search: product.name }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with outdated stock status' do
      let!(:outdated_product) do
        p = create(:product, min_stock: 10)
        create(:product_input, product: p, quantity: 50)
        # Force outdated status
        p.update_column(:stock_status, 'fora_estoque')
        p
      end

      it 'updates stock status in batch during index' do
        get products_path
        expect(response).to have_http_status(:success)
        outdated_product.reload
        expect(outdated_product.stock_status).to eq('em_estoque')
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get products_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ============================================
  # SHOW
  # ============================================
  describe 'GET /products/:id' do
    let(:product) { create(:product) }

    it 'returns success' do
      get product_path(product)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get product_path(product)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ============================================
  # NEW
  # ============================================
  describe 'GET /products/new' do
    it 'returns success' do
      get new_product_path
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get new_product_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ============================================
  # CREATE
  # ============================================
  describe 'POST /products' do
    let(:valid_attributes) do
      {
        name: 'Novo Produto',
        category: 'beleza_cosmeticos',
        min_stock: 10,
        sale_price: 99.90,
        supplier_id: supplier.id
      }
    end

    let(:invalid_attributes) do
      {
        name: '',
        min_stock: -1
      }
    end

    context 'with valid parameters' do
      it 'creates a new Product' do
        expect {
          post products_path, params: { product: valid_attributes }
        }.to change(Product, :count).by(1)
      end

      it 'redirects to the created product' do
        post products_path, params: { product: valid_attributes }
        expect(response).to redirect_to(Product.last)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Product' do
        expect {
          post products_path, params: { product: invalid_attributes }
        }.not_to change(Product, :count)
      end

      it 'returns unprocessable_entity' do
        post products_path, params: { product: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        post products_path, params: { product: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ============================================
  # EDIT
  # ============================================
  describe 'GET /products/:id/edit' do
    let(:product) { create(:product) }

    it 'returns success' do
      get edit_product_path(product)
      expect(response).to have_http_status(:success)
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        get edit_product_path(product)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ============================================
  # UPDATE
  # ============================================
  describe 'PATCH /products/:id' do
    let(:product) { create(:product) }

    let(:new_attributes) do
      { name: 'Produto Atualizado', sale_price: 199.90 }
    end

    let(:invalid_attributes) do
      { name: '', min_stock: -1 }
    end

    context 'with valid parameters' do
      it 'updates the product' do
        patch product_path(product), params: { product: new_attributes }
        product.reload
        expect(product.name).to eq('Produto Atualizado')
        expect(product.sale_price).to eq(199.90)
      end

      it 'redirects to the product' do
        patch product_path(product), params: { product: new_attributes }
        expect(response).to redirect_to(product)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable_entity' do
        patch product_path(product), params: { product: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'deleting cover image' do
      let(:product_with_image) do
        p = create(:product)
        p.cover_image.attach(
          io: StringIO.new('fake jpeg'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
        p
      end

      it 'removes the cover image when requested' do
        expect(product_with_image.cover_image).to be_attached

        patch product_path(product_with_image), params: {
          product: { name: product_with_image.name, cover_image_delete: 'true' }
        }

        expect(response).to redirect_to(product_with_image)
        product_with_image.reload
        expect(product_with_image.cover_image).not_to be_attached
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        patch product_path(product), params: { product: new_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ============================================
  # DESTROY
  # ============================================
  describe 'DELETE /products/:id' do
    let!(:product) { create(:product) }

    context 'with valid request' do
      it 'destroys the product' do
        expect {
          delete product_path(product)
        }.to change(Product, :count).by(-1)
      end

      it 'redirects to products list' do
        delete product_path(product)
        expect(response).to redirect_to(products_url)
      end
    end

    context 'without authentication' do
      before { logout(:user) }

      it 'redirects to login' do
        delete product_path(product)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
