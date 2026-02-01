# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Expense, type: :model do
  # ============================================
  # ASSOCIAÇÕES
  # ============================================
  describe 'associations' do
    it { is_expected.to belong_to(:employee) }
    it { is_expected.to belong_to(:supplier).optional }
  end

  # ============================================
  # VALIDAÇÕES
  # ============================================
  describe 'validations' do
    it { is_expected.to validate_presence_of(:employee_id) }
    it { is_expected.to validate_presence_of(:expense_date) }
    it { is_expected.to validate_presence_of(:expense_type) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:payment_method) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
  end

  # ============================================
  # ENUMS
  # ============================================
  describe 'enums' do
    it 'has correct expense_type values' do
      expected = %w[aluguel utilities salaries supplies maintenance marketing insurance taxes other]
      expect(Expense.expense_types.keys).to eq(expected)
    end

    it 'has correct payment_method values' do
      expected = %w[dinheiro cartao_credito cartao_debito pix transferencia boleto]
      expect(Expense.payment_methods.keys).to eq(expected)
    end

    it 'has correct category values' do
      expected = %w[fixa_mensal fixa_anual esporadica rara]
      expect(Expense.categories.keys).to eq(expected)
    end

    it 'has correct status values' do
      expected = %w[ativa inativa]
      expect(Expense.statuses.keys).to eq(expected)
    end
  end

  # ============================================
  # SCOPES
  # ============================================
  describe 'scopes' do
    let(:employee) { create(:employee) }

    describe '.recent' do
      it 'orders by expense_date desc' do
        old = create(:expense, employee: employee, expense_date: 5.days.ago)
        new = create(:expense, employee: employee, expense_date: 1.day.ago)

        expect(Expense.recent.first).to eq(new)
      end
    end

    describe '.by_employee' do
      let(:employee2) { create(:employee) }
      let!(:expense1) { create(:expense, employee: employee) }
      let!(:expense2) { create(:expense, employee: employee2) }

      it 'filters by employee' do
        expect(Expense.by_employee(employee.id)).to include(expense1)
        expect(Expense.by_employee(employee.id)).not_to include(expense2)
      end
    end

    describe '.by_expense_type' do
      let!(:aluguel) { create(:expense, employee: employee, expense_type: :aluguel) }
      let!(:utilities) { create(:expense, employee: employee, expense_type: :utilities) }

      it 'filters by expense_type' do
        expect(Expense.by_expense_type(:aluguel)).to include(aluguel)
        expect(Expense.by_expense_type(:aluguel)).not_to include(utilities)
      end
    end

    describe '.by_category' do
      let!(:fixed) { create(:expense, employee: employee, category: :fixa_mensal) }
      let!(:sporadic) { create(:expense, employee: employee, category: :esporadica) }

      it 'filters by category' do
        expect(Expense.by_category(:fixa_mensal)).to include(fixed)
        expect(Expense.by_category(:fixa_mensal)).not_to include(sporadic)
      end
    end

    describe '.by_date_range' do
      let!(:inside) { create(:expense, employee: employee, expense_date: 5.days.ago) }
      let!(:outside) { create(:expense, employee: employee, expense_date: 20.days.ago) }

      it 'filters by date range' do
        result = Expense.by_date_range(10.days.ago, Date.current)
        expect(result).to include(inside)
        expect(result).not_to include(outside)
      end
    end

    describe '.monthly_fixed' do
      let!(:monthly) { create(:expense, employee: employee, category: :fixa_mensal) }
      let!(:annual) { create(:expense, employee: employee, category: :fixa_anual) }

      it 'returns only monthly fixed expenses' do
        expect(Expense.monthly_fixed).to include(monthly)
        expect(Expense.monthly_fixed).not_to include(annual)
      end
    end

    describe '.active' do
      let!(:active) { create(:expense, employee: employee, status: :ativa) }
      let!(:inactive) { create(:expense, employee: employee, status: :inativa) }

      it 'returns only active expenses' do
        expect(Expense.active).to include(active)
        expect(Expense.active).not_to include(inactive)
      end
    end

    describe '.inactive' do
      let!(:active) { create(:expense, employee: employee, status: :ativa) }
      let!(:inactive) { create(:expense, employee: employee, status: :inativa) }

      it 'returns only inactive expenses' do
        expect(Expense.inactive).not_to include(active)
        expect(Expense.inactive).to include(inactive)
      end
    end
  end

  # ============================================
  # CLASS METHODS
  # ============================================
  describe '.expense_type_labels' do
    it 'returns hash of labels' do
      labels = Expense.expense_type_labels
      expect(labels[:aluguel]).to eq('Aluguel')
      expect(labels[:utilities]).to eq('Utilidades')
      expect(labels[:salaries]).to eq('Salários')
    end
  end

  describe '.category_labels' do
    it 'returns hash of labels' do
      labels = Expense.category_labels
      expect(labels[:fixa_mensal]).to eq('Fixa Mensal')
      expect(labels[:esporadica]).to eq('Esporádica')
    end
  end

  describe '.status_labels' do
    it 'returns hash of labels' do
      labels = Expense.status_labels
      expect(labels[:ativa]).to eq('Ativa')
      expect(labels[:inativa]).to eq('Inativa')
    end
  end

  # ============================================
  # INSTANCE METHODS
  # ============================================
  describe '#expense_type_label' do
    it 'returns label for expense_type' do
      expense = build(:expense, expense_type: :aluguel)
      expect(expense.expense_type_label).to eq('Aluguel')
    end
  end

  describe '#category_label' do
    it 'returns label for category' do
      expense = build(:expense, category: :fixa_mensal)
      expect(expense.category_label).to eq('Fixa Mensal')
    end
  end

  describe '#status_label' do
    it 'returns label for status' do
      expense = build(:expense, status: :ativa)
      expect(expense.status_label).to eq('Ativa')
    end
  end
end
