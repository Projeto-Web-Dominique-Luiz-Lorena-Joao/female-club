# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProductOutput, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:product_id) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:output_type) }
    it { is_expected.to validate_presence_of(:date_output) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:created_by).class_name('User').optional }
  end

  describe 'enums' do
    it 'defines output_type enum' do
      expect(ProductOutput.output_types.keys).to include('venda', 'extravio', 'perda', 'dano', 'tragedia_climatica', 'devolucao', 'outro')
    end
  end

  describe 'scopes' do
    let!(:product) { create(:product) }

    before do
      create(:product_input, product: product, quantity: 100)
    end

    describe '.recent' do
      it 'orders by date_output desc' do
        old_output = create(:product_output, product: product, date_output: 2.days.ago, quantity: 5)
        new_output = create(:product_output, product: product, date_output: 1.day.ago, quantity: 5)

        expect(ProductOutput.recent.first).to eq(new_output)
      end
    end

    describe '.by_product' do
      it 'filters by product_id' do
        product2 = create(:product)
        create(:product_input, product: product2, quantity: 50)

        output1 = create(:product_output, product: product, quantity: 5)
        output2 = create(:product_output, product: product2, quantity: 5)

        expect(ProductOutput.by_product(product.id)).to include(output1)
        expect(ProductOutput.by_product(product.id)).not_to include(output2)
      end
    end

    describe '.by_output_type' do
      it 'filters by output_type' do
        venda = create(:product_output, product: product, output_type: :venda, quantity: 5)
        perda = create(:product_output, product: product, output_type: :perda, quantity: 5)

        expect(ProductOutput.by_output_type(:venda)).to include(venda)
        expect(ProductOutput.by_output_type(:venda)).not_to include(perda)
      end
    end

    describe '.by_date_range' do
      it 'filters by date range' do
        old_output = create(:product_output, product: product, date_output: 10.days.ago, quantity: 5)
        new_output = create(:product_output, product: product, date_output: 1.day.ago, quantity: 5)

        result = ProductOutput.by_date_range(5.days.ago, Time.current)
        expect(result).to include(new_output)
        expect(result).not_to include(old_output)
      end
    end
  end

  describe '#output_type_labels' do
    it 'returns hash with labels' do
      labels = ProductOutput.output_type_labels
      expect(labels[:venda]).to eq('Venda')
      expect(labels[:extravio]).to eq('Extravio')
      expect(labels[:perda]).to eq('Perda')
      expect(labels[:dano]).to eq('Dano')
      expect(labels[:tragedia_climatica]).to eq('Tragédia Climática')
      expect(labels[:devolucao]).to eq('Devolução')
      expect(labels[:outro]).to eq('Outro')
    end
  end

  describe '#output_label' do
    let(:product) { create(:product) }

    before do
      create(:product_input, product: product, quantity: 100)
    end

    it 'returns translated label for venda' do
      output = create(:product_output, product: product, output_type: :venda, quantity: 5)
      expect(output.output_label).to eq('Venda')
    end

    it 'returns translated label for perda' do
      output = create(:product_output, product: product, output_type: :perda, quantity: 5)
      expect(output.output_label).to eq('Perda')
    end
  end

  describe '#output_badge_class' do
    let(:product) { create(:product) }

    before do
      create(:product_input, product: product, quantity: 100)
    end

    it 'returns green for venda' do
      output = create(:product_output, product: product, output_type: :venda, quantity: 5)
      expect(output.output_badge_class).to eq('bg-green-100 text-green-800')
    end

    it 'returns orange for extravio' do
      output = create(:product_output, product: product, output_type: :extravio, quantity: 5)
      expect(output.output_badge_class).to eq('bg-orange-100 text-orange-800')
    end

    it 'returns red for perda' do
      output = create(:product_output, product: product, output_type: :perda, quantity: 5)
      expect(output.output_badge_class).to eq('bg-red-100 text-red-800')
    end

    it 'returns yellow for dano' do
      output = create(:product_output, product: product, output_type: :dano, quantity: 5)
      expect(output.output_badge_class).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns purple for tragedia_climatica' do
      output = create(:product_output, product: product, output_type: :tragedia_climatica, quantity: 5)
      expect(output.output_badge_class).to eq('bg-purple-100 text-purple-800')
    end

    it 'returns blue for devolucao' do
      output = create(:product_output, product: product, output_type: :devolucao, quantity: 5)
      expect(output.output_badge_class).to eq('bg-blue-100 text-blue-800')
    end

    it 'returns gray for outro' do
      output = create(:product_output, product: product, output_type: :outro, quantity: 5)
      expect(output.output_badge_class).to eq('bg-gray-100 text-gray-800')
    end
  end

  describe 'stock validations' do
    let(:product) { create(:product) }

    before do
      create(:product_input, product: product, quantity: 10)
    end

    describe 'on create' do
      it 'prevents output greater than available stock' do
        output = build(:product_output, product: product, quantity: 50)
        expect(output).not_to be_valid
        expect(output.errors[:base]).to include(/Quantidade insuficiente/)
      end

      it 'allows output within available stock' do
        output = build(:product_output, product: product, quantity: 5)
        expect(output).to be_valid
      end
    end

    describe 'on update' do
      let!(:output) { create(:product_output, product: product, quantity: 5) }

      it 'validates stock when increasing quantity' do
        output.quantity = 20
        expect(output).not_to be_valid
      end

      it 'allows decreasing quantity' do
        output.quantity = 3
        expect(output).to be_valid
      end

      context 'when changing product' do
        let(:new_product) { create(:product) }

        before do
          create(:product_input, product: new_product, quantity: 2)
        end

        it 'validates stock of new product' do
          output.product = new_product
          expect(output).not_to be_valid
          expect(output.errors[:base]).to include(/Quantidade insuficiente no produto selecionado/)
        end
      end
    end
  end
end
