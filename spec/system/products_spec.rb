# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Products', type: :system do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the products list page' do
      visit products_path

      expect(page).to have_content('Produtos')
    end

    context 'with products' do
      let!(:product1) { create(:product, name: 'Shampoo Premium', active: true) }
      let!(:product2) { create(:product, name: 'Condicionador Gold', active: true) }

      it 'displays products in the list' do
        visit products_path

        expect(page).to have_content('Shampoo Premium')
        expect(page).to have_content('Condicionador Gold')
      end

      it 'filters by active status' do
        visit products_path(active: 'true')

        expect(page).to have_content('Shampoo Premium')
      end

      it 'filters by category' do
        visit products_path(category: product1.category)

        expect(page).to have_http_status(:ok)
      end

      it 'searches by name' do
        visit products_path

        fill_in 'search', with: 'Shampoo'
        click_button 'Buscar'

        expect(page).to have_content('Shampoo Premium')
        expect(page).not_to have_content('Condicionador Gold')
      end
    end

    context 'without products' do
      it 'shows empty state' do
        visit products_path

        expect(page).to have_content('Nenhum produto encontrado')
      end
    end
  end

  describe 'Show page' do
    let(:product) { create(:product, name: 'Shampoo Detalhe') }

    it 'displays product details' do
      visit product_path(product)

      expect(page).to have_content('Shampoo Detalhe')
    end

    it 'has edit link' do
      visit product_path(product)

      expect(page).to have_link('Editar')
    end
  end

  describe 'New product' do
    it 'displays the new product form' do
      visit new_product_path

      expect(page).to have_field('Nome do Produto')
      expect(page).to have_field('Preço de Venda')
    end

    it 'creates a new product with valid data' do
      visit new_product_path

      fill_in 'Nome do Produto', with: 'Novo Produto Teste'
      fill_in 'Preço de Venda', with: '59.90'
      fill_in 'Estoque Mínimo', with: '5'
      select 'Beleza e Cosméticos', from: 'Categoria'

      click_button 'Criar Produto'

      expect(page).to have_content('Produto criado com sucesso')
      expect(page).to have_content('Novo Produto Teste')
    end

    it 'shows validation errors with invalid data' do
      visit new_product_path

      fill_in 'Nome do Produto', with: ''
      click_button 'Criar Produto'

      expect(page).to have_content('não pode ficar em branco')
    end
  end

  describe 'Edit product' do
    let(:product) { create(:product, name: 'Produto Editar') }

    it 'displays the edit form with product data' do
      visit edit_product_path(product)

      expect(page).to have_field('Nome do Produto', with: 'Produto Editar')
    end

    it 'updates product with valid data' do
      visit edit_product_path(product)

      fill_in 'Nome do Produto', with: 'Produto Atualizado'
      click_button 'Atualizar Produto'

      expect(page).to have_content('Produto atualizado com sucesso')
      expect(page).to have_content('Produto Atualizado')
    end
  end
end
