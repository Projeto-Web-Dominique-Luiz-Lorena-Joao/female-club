# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Supplier, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:legal_name) }
    it { is_expected.to validate_length_of(:legal_name).is_at_least(3) }

    context 'email validation' do
      subject { build(:supplier) }

      it { is_expected.to allow_value('test@example.com').for(:email) }
      it { is_expected.to allow_value('').for(:email) }
      it { is_expected.to allow_value(nil).for(:email) }
      it { is_expected.not_to allow_value('invalid').for(:email) }
      it { is_expected.not_to allow_value('invalid@').for(:email) }
    end

    context 'email uniqueness' do
      before { create(:supplier, email: 'test@example.com') }

      it 'is case insensitive' do
        supplier = build(:supplier, email: 'TEST@EXAMPLE.COM')
        expect(supplier).not_to be_valid
        expect(supplier.errors[:email]).to include('já está em uso')
      end
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:expenses).dependent(:destroy) }
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(Supplier.statuses).to eq('ativo' => 'ativo', 'inativo' => 'inativo')
    end

    it 'defines product_category enum' do
      expect(Supplier.product_categories.keys).to include('cosmeticos', 'maquiagem', 'cabelo')
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active suppliers' do
        active = create(:supplier, status: :ativo)
        inactive = create(:supplier, status: :inativo)

        expect(Supplier.active).to include(active)
        expect(Supplier.active).not_to include(inactive)
      end
    end

    describe '.inactive' do
      it 'returns only inactive suppliers' do
        active = create(:supplier, status: :ativo)
        inactive = create(:supplier, status: :inativo)

        expect(Supplier.inactive).to include(inactive)
        expect(Supplier.inactive).not_to include(active)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        old_supplier = create(:supplier, created_at: 2.days.ago)
        new_supplier = create(:supplier, created_at: 1.day.ago)

        expect(Supplier.recent.first).to eq(new_supplier)
      end
    end

    describe '.by_category' do
      it 'filters by product_category' do
        cosmeticos = create(:supplier, product_category: :cosmeticos)
        maquiagem = create(:supplier, product_category: :maquiagem)

        expect(Supplier.by_category('cosmeticos')).to include(cosmeticos)
        expect(Supplier.by_category('cosmeticos')).not_to include(maquiagem)
      end

      it 'returns all when category is blank' do
        cosmeticos = create(:supplier, product_category: :cosmeticos)
        maquiagem = create(:supplier, product_category: :maquiagem)

        expect(Supplier.by_category(nil)).to include(cosmeticos, maquiagem)
        expect(Supplier.by_category('')).to include(cosmeticos, maquiagem)
      end
    end
  end

  describe '#display_name' do
    it 'returns trade_name when present' do
      supplier = build(:supplier, trade_name: 'Trade Name', legal_name: 'Legal Name')
      expect(supplier.display_name).to eq('Trade Name')
    end

    it 'returns legal_name when trade_name is blank' do
      supplier = build(:supplier, trade_name: '', legal_name: 'Legal Name')
      expect(supplier.display_name).to eq('Legal Name')
    end

    it 'returns legal_name when trade_name is nil' do
      supplier = build(:supplier, trade_name: nil, legal_name: 'Legal Name')
      expect(supplier.display_name).to eq('Legal Name')
    end
  end

  describe '#formatted_phone' do
    it 'formats 11-digit phone number' do
      supplier = build(:supplier, phone_number: '11987654321')
      expect(supplier.formatted_phone).to eq('(11) 98765-4321')
    end

    it 'returns dash for blank phone' do
      supplier = build(:supplier, phone_number: '')
      expect(supplier.formatted_phone).to eq('-')
    end

    it 'returns dash for nil phone' do
      supplier = build(:supplier, phone_number: nil)
      expect(supplier.formatted_phone).to eq('-')
    end
  end

  describe '#category_badge_color' do
    it 'returns pink for cosmeticos' do
      supplier = build(:supplier, product_category: :cosmeticos)
      expect(supplier.category_badge_color).to eq('bg-pink-100 text-pink-800')
    end

    it 'returns purple for maquiagem' do
      supplier = build(:supplier, product_category: :maquiagem)
      expect(supplier.category_badge_color).to eq('bg-purple-100 text-purple-800')
    end

    it 'returns blue for perfumaria' do
      supplier = build(:supplier, product_category: :perfumaria)
      expect(supplier.category_badge_color).to eq('bg-blue-100 text-blue-800')
    end

    it 'returns orange for cabelo' do
      supplier = build(:supplier, product_category: :cabelo)
      expect(supplier.category_badge_color).to eq('bg-orange-100 text-orange-800')
    end

    it 'returns red for unhas' do
      supplier = build(:supplier, product_category: :unhas)
      expect(supplier.category_badge_color).to eq('bg-red-100 text-red-800')
    end

    it 'returns yellow for pele' do
      supplier = build(:supplier, product_category: :pele)
      expect(supplier.category_badge_color).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns indigo for acessorios' do
      supplier = build(:supplier, product_category: :acessorios)
      expect(supplier.category_badge_color).to eq('bg-indigo-100 text-indigo-800')
    end

    it 'returns gray for equipamentos' do
      supplier = build(:supplier, product_category: :equipamentos)
      expect(supplier.category_badge_color).to eq('bg-gray-200 text-gray-800')
    end

    it 'returns default gray for diversos' do
      supplier = build(:supplier, product_category: :diversos)
      expect(supplier.category_badge_color).to eq('bg-gray-100 text-gray-800')
    end
  end

  describe '#status_badge_color' do
    it 'returns green for ativo' do
      supplier = build(:supplier, status: :ativo)
      expect(supplier.status_badge_color).to eq('bg-green-100 text-green-800')
    end

    it 'returns red for inativo' do
      supplier = build(:supplier, status: :inativo)
      expect(supplier.status_badge_color).to eq('bg-red-100 text-red-800')
    end

    it 'returns default gray for unknown status' do
      supplier = build(:supplier, status: :ativo)
      allow(supplier).to receive(:status).and_return(nil)
      expect(supplier.status_badge_color).to eq('bg-gray-100 text-gray-800')
    end
  end
end
