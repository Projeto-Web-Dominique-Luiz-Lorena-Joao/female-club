# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SaleProduct, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sale) }
    it { is_expected.to belong_to(:product).optional }
    it { is_expected.to have_many(:stock_movements).dependent(:destroy) }
  end

  describe 'validations' do
    context 'when product_id is present' do
      let(:product) { create(:product) }
      let(:sale) { create(:sale) }
      let(:sale_product) { build(:sale_product, sale: sale, product: product) }

      before do
        create(:product_input, product: product, quantity: 100)
      end

      it 'validates presence of quantity' do
        sale_product.quantity = nil
        expect(sale_product).not_to be_valid
        expect(sale_product.errors[:quantity]).to be_present
      end

      it 'validates quantity is greater than 0' do
        sale_product.quantity = 0
        expect(sale_product).not_to be_valid
      end

      it 'validates presence of unit_price' do
        sale_product.unit_price = nil
        expect(sale_product).not_to be_valid
        expect(sale_product.errors[:unit_price]).to be_present
      end

      it 'validates unit_price is greater than or equal to 0' do
        sale_product.unit_price = -1
        expect(sale_product).not_to be_valid
      end
    end

    context 'when product_id is blank' do
      let(:sale) { create(:sale) }
      let(:sale_product) { build(:sale_product, sale: sale, product: nil, quantity: nil, unit_price: nil) }

      it 'does not require quantity' do
        expect(sale_product).to be_valid
      end

      it 'does not require unit_price' do
        expect(sale_product).to be_valid
      end
    end

    context 'product_id validation' do
      let(:sale) { create(:sale) }

      it 'requires product_id when quantity is present' do
        sale_product = build(:sale_product, sale: sale, product: nil, quantity: 5, unit_price: nil)
        expect(sale_product).not_to be_valid
        expect(sale_product.errors[:product_id]).to be_present
      end

      it 'requires product_id when unit_price is present' do
        sale_product = build(:sale_product, sale: sale, product: nil, quantity: nil, unit_price: 10)
        expect(sale_product).not_to be_valid
        expect(sale_product.errors[:product_id]).to be_present
      end
    end
  end

  describe 'stock validation' do
    let(:product) { create(:product) }
    let(:sale) { create(:sale) }

    before do
      create(:product_input, product: product, quantity: 10)
    end

    context 'on new record' do
      it 'prevents sale when stock is insufficient' do
        sale_product = build(:sale_product, sale: sale, product: product, quantity: 50, unit_price: 10)
        expect(sale_product).not_to be_valid
        expect(sale_product.errors[:quantity].first).to include('Estoque insuficiente')
      end

      it 'allows sale when stock is sufficient' do
        sale_product = build(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 10)
        expect(sale_product).to be_valid
      end
    end

    context 'on existing record' do
      let!(:sale_product) { create(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 10) }

      it 'considers previous quantity when updating' do
        # After first sale of 5, stock might be reduced
        # When updating, the validation should consider the original quantity
        sale_product.quantity = 8
        # This should work because previous quantity (5) + current stock should cover the new quantity
        expect(sale_product).to be_valid
      end

      it 'prevents update when adjusted stock is insufficient' do
        sale_product.quantity = 1000
        expect(sale_product).not_to be_valid
      end
    end
  end

  describe '#total_price' do
    let(:product) { create(:product) }
    let(:sale) { create(:sale) }

    before do
      create(:product_input, product: product, quantity: 100)
    end

    it 'calculates total price' do
      sale_product = build(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 25.50)
      expect(sale_product.total_price).to eq(127.50)
    end
  end
end
