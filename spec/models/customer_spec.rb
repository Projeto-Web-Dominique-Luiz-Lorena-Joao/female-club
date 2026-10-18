# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customer, type: :model do
  # ============================================
  # ASSOCIAÇÕES
  # ============================================
  describe 'associations' do
    it { is_expected.to have_many(:sales).dependent(:destroy) }
    it { is_expected.to belong_to(:guarantor).optional }
    it { is_expected.to have_many(:service_appointments).dependent(:destroy) }
  end

  # ============================================
  # VALIDAÇÕES
  # ============================================
  describe 'validations' do
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_length_of(:full_name).is_at_least(3) }
    it { is_expected.to validate_length_of(:phone_number).is_at_least(10).allow_blank }

    describe 'cpf uniqueness' do
      it 'validates uniqueness of CPF' do
        customer1 = create(:customer)
        customer2 = build(:customer, cpf: customer1.cpf)
        expect(customer2).not_to be_valid
        expect(customer2.errors[:cpf]).to include('já está em uso')
      end

      it 'allows blank CPF' do
        customer = build(:customer, cpf: '')
        expect(customer).to be_valid
      end
    end

    describe 'cpf validation' do
      it 'requires valid CPF' do
        customer = build(:customer, cpf: '12345678900')
        expect(customer).not_to be_valid
        expect(customer.errors[:cpf]).to include('não é válido')
      end

      it 'accepts valid CPF' do
        customer = build(:customer) # factory generates valid CPF
        expect(customer).to be_valid
      end
    end

    describe 'email validation' do
      it 'allows blank email' do
        customer = build(:customer, email: '')
        expect(customer).to be_valid
      end

      it 'validates email format' do
        customer = build(:customer, email: 'invalid')
        expect(customer).not_to be_valid
        expect(customer.errors[:email]).to include('não é válido')
      end

      it 'validates email uniqueness' do
        create(:customer, email: 'test@example.com')
        customer = build(:customer, email: 'TEST@EXAMPLE.COM')
        expect(customer).not_to be_valid
        expect(customer.errors[:email]).to include('já está em uso')
      end
    end
  end

  # ============================================
  # SCOPES
  # ============================================
  describe 'scopes' do
    describe '.recent' do
      it 'orders by created_at desc' do
        old = create(:customer, created_at: 2.days.ago)
        new = create(:customer, created_at: 1.day.ago)

        expect(Customer.recent.first).to eq(new)
      end
    end
  end

  # ============================================
  # CALLBACKS
  # ============================================
  describe 'callbacks' do
    describe 'clean_cpf' do
      it 'removes non-digits from CPF' do
        customer = build(:customer)
        original_cpf = customer.cpf
        customer.cpf = "#{original_cpf[0..2]}.#{original_cpf[3..5]}.#{original_cpf[6..8]}-#{original_cpf[9..10]}"
        customer.valid?

        expect(customer.cpf).to eq(original_cpf)
      end
    end
  end

  # ============================================
  # MÉTODOS DE FORMATAÇÃO
  # ============================================
  describe '#formatted_cpf' do
    context 'when cpf is blank' do
      it 'returns dash' do
        customer = build(:customer, cpf: nil)
        expect(customer.formatted_cpf).to eq('-')
      end
    end

    context 'when cpf is present' do
      it 'formats CPF correctly' do
        customer = build(:customer)
        customer.cpf = '12345678901'
        expect(customer.formatted_cpf).to eq('123.456.789-01')
      end
    end
  end

  describe '#formatted_phone' do
    context 'when phone_number is blank' do
      it 'returns dash' do
        customer = build(:customer, phone_number: nil)
        expect(customer.formatted_phone).to eq('-')
      end
    end

    context 'when phone_number is present' do
      it 'formats phone correctly' do
        customer = build(:customer, phone_number: '11987654321')
        expect(customer.formatted_phone).to eq('(11) 98765-4321')
      end
    end
  end

  describe '#formatted_birth_date' do
    context 'when birth_date is nil' do
      it 'returns dash' do
        customer = build(:customer, birth_date: nil)
        expect(customer.formatted_birth_date).to eq('-')
      end
    end

    context 'when birth_date is present' do
      it 'formats date' do
        customer = build(:customer, birth_date: Date.new(1990, 5, 15))
        result = customer.formatted_birth_date
        expect(result).to match(/15.*05.*1990|May 15, 1990|15 de mai/i)
      end
    end
  end

  describe '#age' do
    context 'when birth_date is nil' do
      it 'returns nil' do
        customer = build(:customer, birth_date: nil)
        expect(customer.age).to be_nil
      end
    end

    context 'when birth_date is present' do
      it 'calculates age' do
        customer = build(:customer, birth_date: 30.years.ago)
        expect(customer.age).to eq(30)
      end
    end
  end

  # ============================================
  # MÉTODOS DE ESTATÍSTICAS
  # ============================================
  describe '#total_purchases' do
    let(:employee) { create(:employee) }
    let(:customer) { create(:customer) }

    it 'sums non-cancelled sales' do
      create(:sale, customer: customer, employee: employee, total_amount: 100, status: :pago)
      create(:sale, customer: customer, employee: employee, total_amount: 200, status: :pago)
      create(:sale, customer: customer, employee: employee, total_amount: 50, status: :cancelado)

      expect(customer.total_purchases).to eq(300)
    end

    it 'returns 0 with no sales' do
      expect(customer.total_purchases).to eq(0)
    end
  end

  describe '#last_purchase_date' do
    let(:employee) { create(:employee) }
    let(:customer) { create(:customer) }

    it 'returns most recent sale date' do
      create(:sale, customer: customer, employee: employee, sale_date: 5.days.ago, status: :pago)
      create(:sale, customer: customer, employee: employee, sale_date: 1.day.ago, status: :pago)

      expect(customer.last_purchase_date).to eq(1.day.ago.to_date)
    end

    it 'excludes cancelled sales' do
      create(:sale, customer: customer, employee: employee, sale_date: 5.days.ago, status: :pago)
      create(:sale, customer: customer, employee: employee, sale_date: 1.day.ago, status: :cancelado)

      expect(customer.last_purchase_date).to eq(5.days.ago.to_date)
    end

    it 'returns nil with no sales' do
      expect(customer.last_purchase_date).to be_nil
    end
  end

  describe '#purchases_count' do
    let(:employee) { create(:employee) }
    let(:customer) { create(:customer) }

    it 'counts non-cancelled sales' do
      create(:sale, customer: customer, employee: employee, status: :pago)
      create(:sale, customer: customer, employee: employee, status: :pago)
      create(:sale, customer: customer, employee: employee, status: :cancelado)

      expect(customer.purchases_count).to eq(2)
    end

    it 'returns 0 with no sales' do
      expect(customer.purchases_count).to eq(0)
    end
  end
end
