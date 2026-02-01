# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Employee, type: :model do
  # ============================================
  # ASSOCIAÇÕES
  # ============================================
  describe 'associations' do
    it { is_expected.to have_many(:sales).dependent(:nullify) }
    it { is_expected.to have_many(:service_appointments).dependent(:nullify) }
    it { is_expected.to have_many(:stock_movements).dependent(:nullify) }
    it { is_expected.to have_many(:expenses).dependent(:nullify) }
    it { is_expected.to have_one_attached(:photo) }
  end

  # ============================================
  # VALIDAÇÕES
  # ============================================
  describe 'validations' do
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_length_of(:full_name).is_at_least(3) }
    it { is_expected.to validate_presence_of(:cpf) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:salary).is_greater_than(0).allow_nil }

    describe 'cpf uniqueness' do
      it 'validates uniqueness of CPF' do
        employee1 = create(:employee)
        employee2 = build(:employee, cpf: employee1.cpf)
        expect(employee2).not_to be_valid
        expect(employee2.errors[:cpf]).to include('já está em uso')
      end
    end

    describe 'email validation' do
      it 'allows blank email' do
        employee = build(:employee, email: '')
        expect(employee).to be_valid
      end

      it 'validates email format' do
        employee = build(:employee, email: 'invalid')
        expect(employee).not_to be_valid
        expect(employee.errors[:email]).to include('não é válido')
      end

      it 'validates email uniqueness' do
        create(:employee, email: 'test@example.com')
        employee = build(:employee, email: 'TEST@EXAMPLE.COM')
        expect(employee).not_to be_valid
        expect(employee.errors[:email]).to include('já está em uso')
      end
    end

    describe 'cpf validation' do
      it 'requires valid CPF' do
        employee = build(:employee, cpf: '12345678900')
        expect(employee).not_to be_valid
        expect(employee.errors[:cpf]).to include('não é válido')
      end

      it 'accepts valid CPF' do
        employee = build(:employee) # factory generates valid CPF
        expect(employee).to be_valid
      end
    end

    describe 'photo validation' do
      let(:employee) { build(:employee) }

      context 'when photo type is invalid' do
        before do
          employee.photo.attach(
            io: StringIO.new('fake content'),
            filename: 'test.pdf',
            content_type: 'application/pdf'
          )
        end

        it 'is invalid' do
          expect(employee).not_to be_valid
          expect(employee.errors[:photo]).to include('deve ser uma imagem (JPEG, PNG, GIF ou WebP)')
        end
      end

      context 'when photo is too large' do
        before do
          employee.photo.attach(
            io: StringIO.new('x' * 6.megabytes),
            filename: 'large.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'is invalid' do
          expect(employee).not_to be_valid
          expect(employee.errors[:photo]).to include('é muito grande (máximo 5MB)')
        end
      end
    end
  end

  # ============================================
  # ENUMS
  # ============================================
  describe 'enums' do
    it 'has correct position values' do
      expected = %w[gerente vendedor caixa estoquista manicure cabeleireira esteticista maquiador atendente auxiliar]
      expect(Employee.positions.keys).to eq(expected)
    end

    it 'has correct status values' do
      expected = %w[ativo inativo ferias afastado]
      expect(Employee.statuses.keys).to eq(expected)
    end

    it 'defaults status to ativo' do
      employee = Employee.new
      expect(employee.status).to eq('ativo')
    end
  end

  # ============================================
  # SCOPES
  # ============================================
  describe 'scopes' do
    describe '.active' do
      let!(:ativo) { create(:employee, status: :ativo) }
      let!(:ferias) { create(:employee, status: :ferias) }
      let!(:inativo) { create(:employee, status: :inativo) }

      it 'returns ativo and ferias employees' do
        expect(Employee.active).to include(ativo, ferias)
        expect(Employee.active).not_to include(inativo)
      end
    end

    describe '.working' do
      let!(:ativo) { create(:employee, status: :ativo) }
      let!(:ferias) { create(:employee, status: :ferias) }

      it 'returns only ativo employees' do
        expect(Employee.working).to include(ativo)
        expect(Employee.working).not_to include(ferias)
      end
    end

    describe '.by_position' do
      let!(:gerente) { create(:employee, position: :gerente) }
      let!(:vendedor) { create(:employee, position: :vendedor) }

      it 'filters by position' do
        expect(Employee.by_position(:gerente)).to include(gerente)
        expect(Employee.by_position(:gerente)).not_to include(vendedor)
      end

      it 'returns all when position is blank' do
        expect(Employee.by_position(nil).count).to eq(Employee.count)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        old = create(:employee, created_at: 2.days.ago)
        new = create(:employee, created_at: 1.day.ago)

        expect(Employee.recent.first).to eq(new)
      end
    end
  end

  # ============================================
  # CALLBACKS
  # ============================================
  describe 'callbacks' do
    describe 'clean_cpf' do
      it 'removes non-digits from CPF' do
        employee = build(:employee)
        original_cpf = employee.cpf
        employee.cpf = "#{original_cpf[0..2]}.#{original_cpf[3..5]}.#{original_cpf[6..8]}-#{original_cpf[9..10]}"
        employee.valid?

        expect(employee.cpf).to eq(original_cpf)
      end
    end

    describe 'clean_phone' do
      it 'removes non-digits from phone' do
        employee = build(:employee, phone: '(11) 98765-4321')
        employee.valid?

        expect(employee.phone).to eq('11987654321')
      end
    end
  end

  # ============================================
  # MÉTODOS DE FORMATAÇÃO
  # ============================================
  describe '#formatted_cpf' do
    context 'when cpf is blank' do
      it 'returns dash' do
        employee = build(:employee, cpf: nil)
        expect(employee.formatted_cpf).to eq('-')
      end
    end

    context 'when cpf is present' do
      it 'formats CPF correctly' do
        employee = build(:employee)
        employee.cpf = '12345678901'
        expect(employee.formatted_cpf).to eq('123.456.789-01')
      end
    end
  end

  describe '#formatted_phone' do
    context 'when phone is blank' do
      let(:employee) { build(:employee) }

      before { employee.phone = nil }

      it 'returns dash' do
        expect(employee.formatted_phone).to eq('-')
      end
    end

    context 'with 11 digits (celular)' do
      let(:employee) { build(:employee, phone: '11987654321') }

      it 'formats as mobile' do
        expect(employee.formatted_phone).to eq('(11) 98765-4321')
      end
    end

    context 'with 10 digits (fixo)' do
      let(:employee) { build(:employee, phone: '1134567890') }

      it 'formats as landline' do
        expect(employee.formatted_phone).to eq('(11) 3456-7890')
      end
    end

    context 'with other length' do
      let(:employee) { build(:employee, phone: '123456') }

      it 'returns original phone' do
        expect(employee.formatted_phone).to eq('123456')
      end
    end
  end

  describe '#formatted_salary' do
    context 'when salary is nil' do
      it 'returns dash' do
        employee = build(:employee, salary: nil)
        expect(employee.formatted_salary).to eq('-')
      end
    end

    context 'when salary is present' do
      it 'formats as currency' do
        employee = build(:employee, salary: 2500.50)
        expect(employee.formatted_salary).to eq('R$ 2500.5')
      end
    end
  end

  describe '#years_of_service' do
    context 'when admission_date is nil' do
      it 'returns 0' do
        employee = build(:employee, admission_date: nil)
        expect(employee.years_of_service).to eq(0)
      end
    end

    context 'when admitted 3 years ago' do
      it 'returns 3' do
        employee = build(:employee, admission_date: 3.years.ago)
        expect(employee.years_of_service).to eq(3)
      end
    end
  end

  describe '#formatted_admission_time' do
    context 'when admission_date is nil' do
      it 'returns dash' do
        employee = build(:employee, admission_date: nil)
        expect(employee.formatted_admission_time).to eq('-')
      end
    end

    context 'when admitted years ago' do
      it 'shows years and months' do
        employee = build(:employee, admission_date: 2.years.ago - 3.months)
        result = employee.formatted_admission_time
        expect(result).to match(/\d+ anos? e \d+ mês/)
      end
    end

    context 'when admitted exactly years ago' do
      it 'shows only years' do
        employee = build(:employee, admission_date: 2.years.ago)
        result = employee.formatted_admission_time
        expect(result).to match(/\d+ anos?/)
      end
    end

    context 'when admitted months ago' do
      it 'shows months' do
        employee = build(:employee, admission_date: 3.months.ago)
        result = employee.formatted_admission_time
        expect(result).to match(/\d+ mês/)
      end
    end

    context 'when admitted days ago' do
      it 'shows days' do
        employee = build(:employee, admission_date: 15.days.ago)
        result = employee.formatted_admission_time
        expect(result).to match(/\d+ dias?/)
      end
    end
  end

  describe '#status_color' do
    it 'returns correct color for ativo' do
      employee = build(:employee, status: :ativo)
      expect(employee.status_color).to eq('bg-green-100 text-green-800')
    end

    it 'returns correct color for inativo' do
      employee = build(:employee, status: :inativo)
      expect(employee.status_color).to eq('bg-gray-100 text-gray-800')
    end

    it 'returns correct color for ferias' do
      employee = build(:employee, status: :ferias)
      expect(employee.status_color).to eq('bg-blue-100 text-blue-800')
    end

    it 'returns correct color for afastado' do
      employee = build(:employee, status: :afastado)
      expect(employee.status_color).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns default gray for unknown status' do
      employee = build(:employee, status: :ativo)
      allow(employee).to receive(:status).and_return(nil)
      expect(employee.status_color).to eq('bg-gray-100 text-gray-800')
    end
  end

  describe '#on_payroll?' do
    it 'returns true for ativo' do
      employee = build(:employee, status: :ativo)
      expect(employee.on_payroll?).to be true
    end

    it 'returns true for ferias' do
      employee = build(:employee, status: :ferias)
      expect(employee.on_payroll?).to be true
    end

    it 'returns false for inativo' do
      employee = build(:employee, status: :inativo)
      expect(employee.on_payroll?).to be false
    end

    it 'returns false for afastado' do
      employee = build(:employee, status: :afastado)
      expect(employee.on_payroll?).to be false
    end
  end
end
