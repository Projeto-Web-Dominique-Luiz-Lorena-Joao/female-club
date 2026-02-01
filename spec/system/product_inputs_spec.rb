# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Product Inputs', type: :system do
  let(:user) { create(:user) }
  let(:product) { create(:product, name: 'Shampoo Entrada') }
  let(:supplier) { create(:supplier, legal_name: 'Fornecedor Entrada') }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the product inputs list page' do
      visit product_inputs_path

      expect(page).to have_content('Entradas')
    end

    context 'with product inputs' do
      before do
        create(:product_input, product: product, supplier: supplier, quantity: 50, unit_cost: 10)
      end

      it 'displays entries' do
        visit product_inputs_path

        expect(page).to have_content('Shampoo Entrada')
      end
    end
  end

  describe 'Show page' do
    let(:product_input) { create(:product_input, product: product, supplier: supplier, quantity: 30) }

    it 'displays input details' do
      visit product_input_path(product_input)

      expect(page).to have_content('Shampoo Entrada')
    end
  end

  describe 'New product input' do
    before do
      product
      supplier
    end

    it 'displays the new product input form' do
      visit new_product_input_path

      expect(page).to have_content('Entrada')
      expect(page).to have_field('Quantidade')
      expect(page).to have_field('Custo Unitário')
    end
  end
end
