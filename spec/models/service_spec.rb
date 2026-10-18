# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Service, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than_or_equal_to(0) }

    it 'validates active inclusion' do
      service = Service.new(name: 'Test', price: 100, active: 'ativo')
      expect(service).to be_valid
    end

    it 'validates active value is one of ativo, inativo, arquivado' do
      expect { build(:service, active: 'invalid') }.to raise_error(ArgumentError)
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:sale_services).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:service_appointments).dependent(:restrict_with_error) }
  end

  describe 'enums' do
    it 'defines active enum' do
      expect(Service.actives).to eq('ativo' => 'ativo', 'inativo' => 'inativo', 'arquivado' => 'arquivado')
    end
  end

  describe 'scopes' do
    describe '.ordered_by_name' do
      it 'orders services by name' do
        service_z = create(:service, name: 'Zeta Service')
        service_a = create(:service, name: 'Alpha Service')

        expect(Service.ordered_by_name.first).to eq(service_a)
      end
    end

    describe '.available' do
      it 'returns only active services' do
        active = create(:service, active: 'ativo')
        inactive = create(:service, active: 'inativo')
        archived = create(:service, active: 'arquivado')

        expect(Service.available).to include(active)
        expect(Service.available).not_to include(inactive)
        expect(Service.available).not_to include(archived)
      end
    end
  end

  describe '#formatted_price' do
    it 'formats price as Brazilian currency' do
      service = build(:service, price: 150.50)
      expect(service.formatted_price).to eq('R$ 150.50')
    end

    it 'handles zero price' do
      service = build(:service, price: 0)
      expect(service.formatted_price).to eq('R$ 0.00')
    end

    it 'handles nil price' do
      service = build(:service)
      service.price = nil
      expect(service.formatted_price).to eq('R$ 0.00')
    end
  end

  describe '#status_badge_class' do
    it 'returns green for ativo' do
      service = build(:service, active: 'ativo')
      expect(service.status_badge_class).to eq('bg-green-100 text-green-800')
    end

    it 'returns yellow for inativo' do
      service = build(:service, active: 'inativo')
      expect(service.status_badge_class).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns red for arquivado' do
      service = build(:service, active: 'arquivado')
      expect(service.status_badge_class).to eq('bg-red-100 text-red-800')
    end

    it 'returns gray for unknown status' do
      service = build(:service)
      allow(service).to receive(:active).and_return('unknown')
      expect(service.status_badge_class).to eq('bg-gray-100 text-gray-800')
    end
  end

  describe '#status_label' do
    it 'returns translated label' do
      service = build(:service, active: 'ativo')
      expect(service.status_label).to be_a(String)
    end
  end

  describe 'callbacks' do
    describe 'set_default_status' do
      it 'sets default status to ativo on create' do
        service = Service.new(name: 'Test Service', price: 100)
        service.valid?
        expect(service.active).to eq('ativo')
      end

      it 'does not override existing status' do
        service = Service.new(name: 'Test Service', price: 100, active: 'inativo')
        service.valid?
        expect(service.active).to eq('inativo')
      end
    end
  end
end
