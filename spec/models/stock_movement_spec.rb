# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StockMovement, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:product_id) }
    it { is_expected.to validate_presence_of(:employee_id) }
    it { is_expected.to validate_presence_of(:movement_type) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:employee) }
    it { is_expected.to belong_to(:sale).optional }
    it { is_expected.to belong_to(:sale_product).optional }
  end

  describe 'enums' do
    it 'defines movement_type enum' do
      expect(StockMovement.movement_types.keys).to include('aquisicao', 'venda', 'perda_extravio', 'devolucao')
    end
  end

  describe 'scopes' do
    let!(:product) { create(:product) }
    let!(:employee) { create(:employee) }
    let!(:sale) { create(:sale) }

    describe '.recent' do
      it 'orders by created_at desc' do
        old_movement = create(:stock_movement, product: product, employee: employee, sale: sale, created_at: 2.days.ago)
        new_movement = create(:stock_movement, product: product, employee: employee, sale: sale, created_at: 1.day.ago)

        expect(StockMovement.recent.first).to eq(new_movement)
      end
    end

    describe '.by_product' do
      it 'filters by product_id' do
        product2 = create(:product)
        movement1 = create(:stock_movement, product: product, employee: employee, sale: sale)
        movement2 = create(:stock_movement, product: product2, employee: employee, sale: sale)

        expect(StockMovement.by_product(product.id)).to include(movement1)
        expect(StockMovement.by_product(product.id)).not_to include(movement2)
      end
    end

    describe '.by_movement_type' do
      it 'filters by movement type' do
        venda = create(:stock_movement, product: product, employee: employee, sale: sale, movement_type: :venda)
        aquisicao = create(:stock_movement, :aquisicao, product: product, employee: employee)

        expect(StockMovement.by_movement_type(:venda)).to include(venda)
        expect(StockMovement.by_movement_type(:venda)).not_to include(aquisicao)
      end
    end

    describe '.by_date_range' do
      it 'filters by date range' do
        old_movement = create(:stock_movement, product: product, employee: employee, sale: sale, created_at: 10.days.ago)
        new_movement = create(:stock_movement, product: product, employee: employee, sale: sale, created_at: 1.day.ago)

        result = StockMovement.by_date_range(5.days.ago, Time.current)
        expect(result).to include(new_movement)
        expect(result).not_to include(old_movement)
      end
    end

    describe '.sales' do
      it 'returns only sale movements' do
        venda = create(:stock_movement, product: product, employee: employee, sale: sale, movement_type: :venda)
        aquisicao = create(:stock_movement, :aquisicao, product: product, employee: employee)

        expect(StockMovement.sales).to include(venda)
        expect(StockMovement.sales).not_to include(aquisicao)
      end
    end

    describe '.acquisitions' do
      it 'returns only acquisition movements' do
        venda = create(:stock_movement, product: product, employee: employee, sale: sale, movement_type: :venda)
        aquisicao = create(:stock_movement, :aquisicao, product: product, employee: employee)

        expect(StockMovement.acquisitions).to include(aquisicao)
        expect(StockMovement.acquisitions).not_to include(venda)
      end
    end

    describe '.losses' do
      it 'returns only loss movements' do
        perda = create(:stock_movement, :perda, product: product, employee: employee)
        venda = create(:stock_movement, product: product, employee: employee, sale: sale, movement_type: :venda)

        expect(StockMovement.losses).to include(perda)
        expect(StockMovement.losses).not_to include(venda)
      end
    end
  end

  describe '#movement_type_labels' do
    it 'returns hash with labels' do
      labels = StockMovement.movement_type_labels
      expect(labels[:aquisicao]).to eq('Aquisição')
      expect(labels[:venda]).to eq('Venda')
      expect(labels[:perda_extravio]).to eq('Perda/Extravio')
      expect(labels[:devolucao]).to eq('Devolução')
      expect(labels[:ajuste_estoque]).to eq('Ajuste de Estoque')
      expect(labels[:transferencia]).to eq('Transferência')
      expect(labels[:cancellation_return]).to eq('Devolução por Cancelamento')
    end
  end

  describe '#movement_label' do
    let(:product) { create(:product) }
    let(:employee) { create(:employee) }
    let(:sale) { create(:sale) }

    it 'returns translated label' do
      movement = create(:stock_movement, product: product, employee: employee, sale: sale, movement_type: :venda)
      expect(movement.movement_label).to eq('Venda')
    end

    it 'returns raw type when label not found' do
      movement = create(:stock_movement, :aquisicao, product: product, employee: employee)
      allow(movement).to receive(:movement_type).and_return('unknown')
      expect(movement.movement_label).to eq('unknown')
    end
  end
end
