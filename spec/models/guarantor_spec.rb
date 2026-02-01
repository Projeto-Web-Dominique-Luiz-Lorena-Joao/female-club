# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Guarantor, type: :model do
  describe 'validations' do
    subject { build(:guarantor) }

    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_length_of(:full_name).is_at_least(3).is_at_most(100) }
    it { is_expected.to validate_presence_of(:status) }

    context 'cpf validation' do
      it 'validates CPF format' do
        guarantor = build(:guarantor, cpf: '12345678901')  # Invalid CPF
        expect(guarantor).not_to be_valid
        expect(guarantor.errors[:cpf]).to include('não é válido')
      end

      it 'validates CPF uniqueness' do
        create(:guarantor, cpf: '529.982.247-25')
        guarantor = build(:guarantor, cpf: '52998224725')
        expect(guarantor).not_to be_valid
      end

      it 'allows blank CPF' do
        guarantor = build(:guarantor, cpf: '')
        guarantor.valid?
        expect(guarantor.errors[:cpf]).to be_empty
      end
    end

    context 'phone validation' do
      it 'validates phone with 10 digits' do
        guarantor = build(:guarantor, phone: '1198765432')
        expect(guarantor).to be_valid
      end

      it 'validates phone with 11 digits' do
        guarantor = build(:guarantor, phone: '11987654321')
        expect(guarantor).to be_valid
      end

      it 'invalidates phone with wrong length' do
        guarantor = build(:guarantor, phone: '123456789')
        expect(guarantor).not_to be_valid
      end

      it 'allows blank phone' do
        guarantor = build(:guarantor, phone: '')
        guarantor.valid?
        expect(guarantor.errors[:phone]).to be_empty
      end
    end

    context 'relationship validation' do
      it 'validates relationship is valid enum value when present' do
        guarantor = build(:guarantor, relationship: :pai)
        expect(guarantor).to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to have_one(:customer).dependent(:nullify) }
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(Guarantor.statuses).to eq('ativo' => 'ativo', 'inativo' => 'inativo')
    end

    it 'defines relationship enum' do
      expect(Guarantor.relationships.keys).to include('pai', 'mae', 'irmao', 'esposo')
    end
  end

  describe 'scopes' do
    describe '.with_cpf' do
      it 'returns only guarantors with CPF' do
        with_cpf = create(:guarantor, cpf: '529.982.247-25')
        without_cpf = create(:guarantor, cpf: nil)

        expect(Guarantor.with_cpf).to include(with_cpf)
        expect(Guarantor.with_cpf).not_to include(without_cpf)
      end
    end

    describe '.with_phone' do
      it 'returns only guarantors with phone' do
        with_phone = create(:guarantor, phone: '11987654321')
        without_phone = create(:guarantor, phone: nil)

        expect(Guarantor.with_phone).to include(with_phone)
        expect(Guarantor.with_phone).not_to include(without_phone)
      end
    end

    describe '.by_relationship' do
      it 'filters by relationship' do
        pai = create(:guarantor, relationship: :pai)
        mae = create(:guarantor, relationship: :mae)

        expect(Guarantor.by_relationship(:pai)).to include(pai)
        expect(Guarantor.by_relationship(:pai)).not_to include(mae)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        old_guarantor = create(:guarantor, created_at: 2.days.ago)
        new_guarantor = create(:guarantor, created_at: 1.day.ago)

        expect(Guarantor.recent.first).to eq(new_guarantor)
      end
    end
  end

  describe '#formatted_cpf' do
    it 'formats CPF with dots and dash' do
      guarantor = build(:guarantor, cpf: '52998224725')
      expect(guarantor.formatted_cpf).to eq('529.982.247-25')
    end

    it 'returns nil for nil CPF' do
      guarantor = build(:guarantor, cpf: nil)
      expect(guarantor.formatted_cpf).to be_nil
    end

    it 'returns nil for blank CPF' do
      guarantor = build(:guarantor, cpf: '')
      expect(guarantor.formatted_cpf).to be_nil
    end
  end

  describe '#formatted_phone' do
    it 'formats 11-digit phone' do
      guarantor = build(:guarantor, phone: '11987654321')
      expect(guarantor.formatted_phone).to eq('(11) 98765-4321')
    end

    it 'formats 10-digit phone' do
      guarantor = build(:guarantor, phone: '1198765432')
      expect(guarantor.formatted_phone).to eq('(11) 9876-5432')
    end

    it 'returns nil for nil phone' do
      guarantor = build(:guarantor, phone: nil)
      expect(guarantor.formatted_phone).to be_nil
    end

    it 'returns nil for blank phone' do
      guarantor = build(:guarantor, phone: '')
      expect(guarantor.formatted_phone).to be_nil
    end

    it 'returns raw phone for other lengths' do
      guarantor = build(:guarantor)
      guarantor.phone = '123456789'  # 9 digits
      expect(guarantor.formatted_phone).to eq('123456789')
    end
  end

  describe 'normalization callbacks' do
    describe 'normalize_cpf' do
      it 'removes non-numeric characters from CPF' do
        guarantor = build(:guarantor, cpf: '529.982.247-25')
        guarantor.valid?
        expect(guarantor.cpf).to eq('52998224725')
      end

      it 'sets CPF to nil when blank' do
        guarantor = build(:guarantor, cpf: '')
        guarantor.valid?
        expect(guarantor.cpf).to be_nil
      end
    end

    describe 'normalize_phone' do
      it 'removes non-numeric characters from phone' do
        guarantor = build(:guarantor, phone: '(11) 98765-4321')
        guarantor.valid?
        expect(guarantor.phone).to eq('11987654321')
      end

      it 'sets phone to nil when blank' do
        guarantor = build(:guarantor, phone: '')
        guarantor.valid?
        expect(guarantor.phone).to be_nil
      end
    end
  end
end
