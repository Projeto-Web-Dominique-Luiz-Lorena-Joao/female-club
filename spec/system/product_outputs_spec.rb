# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Product Outputs', type: :system do
  let(:user) { create(:user) }
  let(:product) { create(:product, :with_stock, name: 'Shampoo Saída', initial_stock: 100) }

  before do
    login_as(user, scope: :user)
  end

  describe 'Index page' do
    it 'displays the product outputs list page' do
      visit product_outputs_path

      expect(page).to have_content('Saídas')
    end

    context 'with product outputs' do
      before do
        create(:product_output, product: product, quantity: 10, output_type: 'perda')
      end

      it 'displays outputs' do
        visit product_outputs_path

        expect(page).to have_content('Shampoo Saída')
      end
    end
  end

  describe 'Show page' do
    let(:product_output) { create(:product_output, product: product, quantity: 5) }

    it 'displays output details' do
      visit product_output_path(product_output)

      expect(page).to have_content('Shampoo Saída')
    end
  end

  describe 'New product output' do
    before { product }

    it 'displays the new product output form' do
      visit new_product_output_path

      expect(page).to have_content('Saída')
      expect(page).to have_field('Quantidade')
    end
  end
end
