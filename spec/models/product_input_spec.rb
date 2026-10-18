# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProductInput, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:product_id) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:date_input) }
    it { is_expected.to validate_numericality_of(:unit_cost).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:supplier).optional }
    it { is_expected.to belong_to(:created_by).class_name('User').optional }
  end

  describe 'scopes' do
    let!(:product1) { create(:product) }
    let!(:product2) { create(:product) }
    let!(:supplier) { create(:supplier) }

    describe '.recent' do
      it 'orders by date_input desc' do
        old_input = create(:product_input, product: product1, date_input: 2.days.ago)
        new_input = create(:product_input, product: product1, date_input: 1.day.ago)

        expect(ProductInput.recent.first).to eq(new_input)
      end
    end

    describe '.by_product' do
      it 'filters by product_id' do
        input1 = create(:product_input, product: product1)
        input2 = create(:product_input, product: product2)

        expect(ProductInput.by_product(product1.id)).to include(input1)
        expect(ProductInput.by_product(product1.id)).not_to include(input2)
      end
    end

    describe '.by_supplier' do
      it 'filters by supplier_id' do
        input1 = create(:product_input, product: product1, supplier: supplier)
        input2 = create(:product_input, product: product1, supplier: nil)

        expect(ProductInput.by_supplier(supplier.id)).to include(input1)
        expect(ProductInput.by_supplier(supplier.id)).not_to include(input2)
      end
    end

    describe '.by_date_range' do
      it 'filters by date range' do
        old_input = create(:product_input, product: product1, date_input: 10.days.ago)
        new_input = create(:product_input, product: product1, date_input: 1.day.ago)

        result = ProductInput.by_date_range(5.days.ago, Time.current)
        expect(result).to include(new_input)
        expect(result).not_to include(old_input)
      end
    end
  end

  describe '#total_cost' do
    it 'calculates total cost' do
      input = build(:product_input, quantity: 10, unit_cost: 5.50)
      expect(input.total_cost).to eq(55.0)
    end

    it 'handles nil quantity' do
      input = build(:product_input)
      input.quantity = nil
      input.unit_cost = 5.50
      expect(input.total_cost).to eq(0)
    end

    it 'handles nil unit_cost' do
      input = build(:product_input, quantity: 10, unit_cost: nil)
      expect(input.total_cost).to eq(0)
    end
  end

  describe 'callbacks' do
    let(:product) { create(:product, quantity_in: 100) }

    describe 'after_create_commit' do
      it 'updates product stock after create' do
        expect {
          create(:product_input, product: product, quantity: 50)
        }.to change { product.reload.quantity_in }.by(50)
      end

      it 'updates last_replenishment_date' do
        create(:product_input, product: product, quantity: 10)
        expect(product.reload.last_replenishment_date).to be_present
      end
    end

    describe 'after_update_commit' do
      let!(:input) { create(:product_input, product: product, quantity: 20) }

      context 'when quantity changes' do
        it 'updates product stock with difference' do
          product.reload
          initial_qty = product.quantity_in

          input.update(quantity: 30)
          expect(product.reload.quantity_in).to eq(initial_qty + 10)
        end
      end

      context 'when product_id changes' do
        let(:new_product) { create(:product, quantity_in: 50) }

        it 'decreases old product stock' do
          old_qty = product.reload.quantity_in
          input.update(product: new_product)
          expect(product.reload.quantity_in).to eq(old_qty - 20)
        end

        it 'increases new product stock' do
          old_new_qty = new_product.quantity_in
          input.update(product: new_product)
          expect(new_product.reload.quantity_in).to eq(old_new_qty + 20)
        end
      end
    end

    describe 'after_destroy_commit' do
      let!(:input) { create(:product_input, product: product, quantity: 30) }

      it 'rolls back product stock' do
        current_qty = product.reload.quantity_in

        input.destroy
        expect(product.reload.quantity_in).to eq(current_qty - 30)
      end

      it 'does not allow negative stock' do
        product.update_column(:quantity_in, 10)

        input.destroy
        expect(product.reload.quantity_in).to be >= 0
      end
    end
  end
end
