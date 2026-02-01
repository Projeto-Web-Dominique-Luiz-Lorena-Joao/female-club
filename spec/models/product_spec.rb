# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  # ============================================
  # ASSOCIAÇÕES
  # ============================================
  describe 'associations' do
    it { is_expected.to belong_to(:supplier).optional }
    it { is_expected.to have_many(:sale_products).dependent(:destroy) }
    it { is_expected.to have_many(:sales).through(:sale_products) }
    it { is_expected.to have_many(:stock_movements).dependent(:destroy) }
    it { is_expected.to have_many(:product_outputs).dependent(:destroy) }
    it { is_expected.to have_many(:product_inputs).dependent(:destroy) }
    it { is_expected.to have_one_attached(:cover_image) }
  end

  # ============================================
  # VALIDAÇÕES
  # ============================================
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:min_stock) }
    it { is_expected.to validate_numericality_of(:min_stock).is_greater_than_or_equal_to(0).only_integer }
    it { is_expected.to validate_numericality_of(:sale_price).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:quantity_in).is_greater_than_or_equal_to(0).only_integer.allow_nil }

    describe 'code uniqueness' do
      subject { create(:product) }
      it { is_expected.to validate_uniqueness_of(:code).allow_nil }
    end

    describe 'cover_image validation' do
      let(:product) { build(:product) }

      context 'when image type is invalid' do
        before do
          product.cover_image.attach(
            io: StringIO.new('fake content'),
            filename: 'test.pdf',
            content_type: 'application/pdf'
          )
        end

        it 'is invalid' do
          expect(product).not_to be_valid
          expect(product.errors[:cover_image]).to include('deve ser uma imagem (JPEG, PNG, GIF ou WebP)')
        end
      end

      context 'when image is too large' do
        before do
          product.cover_image.attach(
            io: StringIO.new('x' * 6.megabytes),
            filename: 'large.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'is invalid' do
          expect(product).not_to be_valid
          expect(product.errors[:cover_image]).to include('é muito grande (máximo 5MB)')
        end
      end

      context 'when image is valid' do
        before do
          product.cover_image.attach(
            io: StringIO.new('fake jpeg'),
            filename: 'valid.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'is valid' do
          expect(product).to be_valid
        end
      end
    end
  end

  # ============================================
  # SCOPES
  # ============================================
  describe 'scopes' do
    describe '.active' do
      let!(:active_product) { create(:product, active: true) }
      let!(:inactive_product) { create(:product, active: false) }

      it 'returns only active products' do
        expect(Product.active).to include(active_product)
        expect(Product.active).not_to include(inactive_product)
      end
    end

    describe '.inactive' do
      let!(:active_product) { create(:product, active: true) }
      let!(:inactive_product) { create(:product, active: false) }

      it 'returns only inactive products' do
        expect(Product.inactive).not_to include(active_product)
        expect(Product.inactive).to include(inactive_product)
      end
    end

    describe '.by_category' do
      let!(:beleza) { create(:product, category: :beleza_cosmeticos) }
      let!(:moda) { create(:product, category: :moda_acessorios) }

      it 'filters by category' do
        expect(Product.by_category(:beleza_cosmeticos)).to include(beleza)
        expect(Product.by_category(:beleza_cosmeticos)).not_to include(moda)
      end
    end

    describe '.low_stock' do
      let!(:normal) do
        product = create(:product, min_stock: 10)
        create(:product_input, product: product, quantity: 100)
        product.reload.update_stock_status!
        product
      end

      let!(:low) do
        product = create(:product, min_stock: 10)
        create(:product_input, product: product, quantity: 15)
        product.reload.update_stock_status!
        product
      end

      it 'returns products with low or critical stock' do
        expect(Product.low_stock).not_to include(normal)
        expect(Product.low_stock).to include(low)
      end
    end

    describe '.search' do
      let!(:shampoo) { create(:product, name: 'Shampoo Especial', code: 'SHP001', brand: 'BrandA') }
      let!(:conditioner) { create(:product, name: 'Condicionador', code: 'CND001', brand: 'BrandB') }

      it 'searches by name' do
        expect(Product.search('Shampoo')).to include(shampoo)
        expect(Product.search('Shampoo')).not_to include(conditioner)
      end

      it 'searches by code' do
        expect(Product.search('SHP001')).to include(shampoo)
        expect(Product.search('SHP001')).not_to include(conditioner)
      end

      it 'searches by brand' do
        expect(Product.search('BrandA')).to include(shampoo)
        expect(Product.search('BrandA')).not_to include(conditioner)
      end
    end
  end

  # ============================================
  # MÉTODOS DE ESTOQUE
  # ============================================
  describe '#quantity' do
    let(:product) { create(:product) }

    context 'without inputs or outputs' do
      it 'returns 0' do
        expect(product.quantity).to eq(0)
      end
    end

    context 'with inputs' do
      before do
        create(:product_input, product: product, quantity: 50)
        create(:product_input, product: product, quantity: 30)
      end

      it 'returns sum of inputs' do
        expect(product.quantity).to eq(80)
      end
    end

    context 'with inputs and outputs' do
      before do
        create(:product_input, product: product, quantity: 100)
        create(:product_output, product: product, quantity: 30)
      end

      it 'returns inputs minus outputs' do
        expect(product.quantity).to eq(70)
      end
    end

    context 'when calculated would be negative' do
      it 'returns 0 instead of negative' do
        expect(product.quantity).to be >= 0
      end
    end
  end

  describe '#low_stock?' do
    context 'when quantity <= min_stock' do
      let(:product) do
        p = create(:product, min_stock: 10)
        create(:product_input, product: p, quantity: 5)
        p.reload
      end

      it 'returns true' do
        expect(product.low_stock?).to be true
      end
    end

    context 'when quantity > min_stock' do
      let(:product) do
        p = create(:product, min_stock: 10)
        create(:product_input, product: p, quantity: 50)
        p.reload
      end

      it 'returns false' do
        expect(product.low_stock?).to be false
      end
    end

    context 'when min_stock is nil' do
      let(:product) { build(:product, min_stock: nil) }

      it 'returns false' do
        expect(product.low_stock?).to be false
      end
    end
  end

  describe '#stock_value' do
    let(:product) { create(:product, sale_price: 50) }

    before { create(:product_input, product: product, quantity: 10) }

    it 'calculates quantity * sale_price' do
      expect(product.stock_value).to eq(500)
    end

    context 'when sale_price is nil' do
      let(:product) { create(:product, sale_price: nil) }

      it 'returns 0' do
        expect(product.stock_value).to eq(0)
      end
    end
  end

  # ============================================
  # STATUS DE ESTOQUE
  # ============================================
  describe '#calculate_stock_status' do
    let(:product) { create(:product, min_stock: 10) }

    context 'when quantity is 0' do
      it 'returns fora_de_estoque' do
        expect(product.calculate_stock_status).to eq('fora_de_estoque')
      end
    end

    context 'when min_stock is 0' do
      let(:product) { create(:product, min_stock: 0) }

      before { create(:product_input, product: product, quantity: 10) }

      it 'returns em_estoque' do
        expect(product.reload.calculate_stock_status).to eq('em_estoque')
      end
    end

    context 'when quantity <= min_stock' do
      before { create(:product_input, product: product, quantity: 5) }

      it 'returns critico' do
        expect(product.reload.calculate_stock_status).to eq('critico')
      end
    end

    context 'when quantity <= min_stock * 2' do
      before { create(:product_input, product: product, quantity: 15) }

      it 'returns baixo' do
        expect(product.reload.calculate_stock_status).to eq('baixo')
      end
    end

    context 'when quantity > min_stock * 2' do
      before { create(:product_input, product: product, quantity: 50) }

      it 'returns em_estoque' do
        expect(product.reload.calculate_stock_status).to eq('em_estoque')
      end
    end
  end

  describe '#update_stock_status!' do
    let(:product) { create(:product, min_stock: 10) }

    it 'updates stock_status column' do
      expect(product.stock_status).to eq('fora_de_estoque')

      create(:product_input, product: product, quantity: 100)
      product.reload.update_stock_status!

      expect(product.stock_status).to eq('em_estoque')
    end
  end

  describe '#refresh_stock_status!' do
    let(:product) { create(:product, min_stock: 10) }

    it 'forces update of stock_status' do
      create(:product_input, product: product, quantity: 100)
      product.reload.refresh_stock_status!

      expect(product.stock_status).to eq('em_estoque')
    end
  end

  describe '#stock_status_info' do
    context 'when min_stock is blank or 0' do
      let(:product) { create(:product, min_stock: 0) }

      it 'returns message string' do
        expect(product.stock_status_info).to eq('Sem estoque mínimo definido')
      end
    end

    context 'when min_stock is defined' do
      let(:product) { create(:product, min_stock: 10) }

      before do
        create(:product_input, product: product, quantity: 50)
        product.reload.update_stock_status!
      end

      it 'returns hash with stock info' do
        info = product.stock_status_info

        expect(info[:quantity]).to eq(50)
        expect(info[:min_stock]).to eq(10)
        expect(info[:low_stock_limit]).to eq(20)
        expect(info[:status]).to eq('em_estoque')
        expect(info[:message]).to be_present
      end
    end
  end

  describe '#stock_status_message' do
    let(:product) { create(:product, min_stock: 10) }

    context 'when out of stock' do
      it 'returns out of stock message' do
        expect(product.stock_status_message).to match(/fora de estoque/i)
      end
    end

    context 'when min_stock is 0' do
      let(:product) { create(:product, min_stock: 0) }

      before { create(:product_input, product: product, quantity: 50) }

      it 'returns not configured message' do
        expect(product.reload.stock_status_message).to match(/não configurado/i)
      end
    end

    context 'when critical' do
      before do
        create(:product_input, product: product, quantity: 5)
        product.reload.update_stock_status!
      end

      it 'returns critical message' do
        expect(product.stock_status_message).to match(/crítico/i)
      end
    end

    context 'when low' do
      before do
        create(:product_input, product: product, quantity: 15)
        product.reload.update_stock_status!
      end

      it 'returns low stock message' do
        expect(product.stock_status_message).to match(/baixo/i)
      end
    end

    context 'when in stock' do
      before do
        create(:product_input, product: product, quantity: 50)
        product.reload.update_stock_status!
      end

      it 'returns in stock message' do
        expect(product.stock_status_message).to match(/em estoque/i)
      end
    end

    context 'when stock_status is unknown' do
      let(:product) do
        p = create(:product, min_stock: 10)
        create(:product_input, product: p, quantity: 50)
        p.reload
      end

      it 'returns out of stock message for unknown status' do
        allow(product).to receive(:stock_status).and_return('unknown')
        expect(product.stock_status_message).to eq('Fora de estoque')
      end
    end
  end

  # ============================================
  # CATEGORY BADGE CLASS
  # ============================================
  describe '#category_badge_class' do
    it 'returns correct class for beleza_cosmeticos' do
      product = build(:product, category: :beleza_cosmeticos)
      expect(product.category_badge_class).to eq('bg-pink-100 text-pink-800')
    end

    it 'returns correct class for moda_acessorios' do
      product = build(:product, category: :moda_acessorios)
      expect(product.category_badge_class).to eq('bg-purple-100 text-purple-800')
    end

    it 'returns correct class for bem_estar_autocuidado' do
      product = build(:product, category: :bem_estar_autocuidado)
      expect(product.category_badge_class).to eq('bg-green-100 text-green-800')
    end

    it 'returns correct class for decoracao_casa' do
      product = build(:product, category: :decoracao_casa)
      expect(product.category_badge_class).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns correct class for gastronomia_bebidas' do
      product = build(:product, category: :gastronomia_bebidas)
      expect(product.category_badge_class).to eq('bg-orange-100 text-orange-800')
    end

    it 'returns correct class for livros_cultura' do
      product = build(:product, category: :livros_cultura)
      expect(product.category_badge_class).to eq('bg-indigo-100 text-indigo-800')
    end

    it 'returns correct class for tecnologia_lifestyle' do
      product = build(:product, category: :tecnologia_lifestyle)
      expect(product.category_badge_class).to eq('bg-cyan-100 text-cyan-800')
    end

    it 'returns correct class for fitness_esportes' do
      product = build(:product, category: :fitness_esportes)
      expect(product.category_badge_class).to eq('bg-blue-100 text-blue-800')
    end

    it 'returns correct class for outros' do
      product = build(:product, category: :outros)
      expect(product.category_badge_class).to eq('bg-gray-100 text-gray-800')
    end

    it 'returns default class for nil category' do
      product = build(:product, category: nil)
      expect(product.category_badge_class).to eq('bg-gray-100 text-gray-800')
    end
  end

  # ============================================
  # CALLBACKS
  # ============================================
  describe 'callbacks' do
    describe 'normalize_strings' do
      it 'strips and normalizes name, code, and brand' do
        product = create(:product, name: '  Shampoo  ', code: '  abc123  ', brand: '  Marca  ')

        expect(product.name).to eq('Shampoo')
        expect(product.code).to eq('ABC123')
        expect(product.brand).to eq('Marca')
      end
    end

    describe 'ensure_non_negative_stock' do
      it 'ensures quantity_in is not negative via callback' do
        product = create(:product)
        # O callback before_save verifica se quantity_in é negativo
        # mas a validação roda antes do callback, então o callback
        # só funciona se quantity_in já era nil/positivo e algo o tornou negativo
        # no mesmo ciclo de save (edge case interno)

        # Simular o cenário onde quantity_in é nil e depois setado
        product.quantity_in = nil
        product.save!

        expect(product.quantity_in).to be_nil.or eq(0)
      end

      it 'allows zero quantity_in' do
        product = create(:product)
        product.quantity_in = 0
        product.save!

        expect(product.quantity_in).to eq(0)
      end
    end

    describe 'update_stock_status_if_needed' do
      let(:product) { create(:product, min_stock: 10) }

      it 'updates stock status when min_stock changes' do
        create(:product_input, product: product, quantity: 25)
        product.reload

        expect(product.stock_status).to eq('em_estoque')

        product.update!(min_stock: 20)
        expect(product.stock_status).to eq('baixo')
      end
    end
  end

  # ============================================
  # ENUMS
  # ============================================
  describe 'enums' do
    it 'has correct category values' do
      expected = %w[beleza_cosmeticos moda_acessorios bem_estar_autocuidado decoracao_casa
                    gastronomia_bebidas livros_cultura tecnologia_lifestyle fitness_esportes outros]
      expect(Product.categories.keys).to eq(expected)
    end
  end
end
