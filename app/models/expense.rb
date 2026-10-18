class Expense < ApplicationRecord
  belongs_to :employee
  belongs_to :supplier, optional: true

  enum :expense_type, {
    aluguel: "aluguel",
    utilities: "utilities",
    salaries: "salaries",
    supplies: "supplies",
    maintenance: "maintenance",
    marketing: "marketing",
    insurance: "insurance",
    taxes: "taxes",
    other: "other"
  }

  enum :payment_method, {
    dinheiro: "dinheiro",
    cartao_credito: "cartao_credito",
    cartao_debito: "cartao_debito",
    pix: "pix",
    transferencia: "transferencia",
    boleto: "boleto"
  }

  enum :category, {
    fixa_mensal: "fixa_mensal",
    fixa_anual: "fixa_anual",
    esporadica: "esporadica",
    rara: "rara"
  }

  enum :status, {
    ativa: "ativa",
    inativa: "inativa"
  }

  validates :employee_id, presence: true
  validates :expense_date, presence: true
  validates :expense_type, presence: true, inclusion: { in: expense_types.keys.map(&:to_s) }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true, inclusion: { in: payment_methods.keys.map(&:to_s) }
  validates :category, presence: true, inclusion: { in: categories.keys.map(&:to_s) }
  validates :status, presence: true, inclusion: { in: statuses.keys.map(&:to_s) }

  scope :recent, -> { order(expense_date: :desc) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }
  scope :by_supplier, ->(supplier_id) { where(supplier_id: supplier_id) }
  scope :by_expense_type, ->(type) { where(expense_type: type) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_payment_method, ->(method) { where(payment_method: method) }
  scope :by_date_range, ->(start_date, end_date) { where(expense_date: start_date..end_date) }
  scope :monthly_fixed, -> { where(category: "fixa_mensal") }
  scope :annual_fixed, -> { where(category: "fixa_anual") }
  scope :active, -> { where(status: "ativa") }
  scope :inactive, -> { where(status: "inativa") }

  def self.expense_type_labels
    {
      aluguel: "Aluguel",
      utilities: "Utilidades",
      salaries: "Salários",
      supplies: "Suprimentos",
      maintenance: "Manutenção",
      marketing: "Marketing",
      insurance: "Seguro",
      taxes: "Impostos",
      other: "Outro"
    }
  end

  def self.category_labels
    {
      fixa_mensal: "Fixa Mensal",
      fixa_anual: "Fixa Anual",
      esporadica: "Esporádica",
      rara: "Rara"
    }
  end

  def self.status_labels
    {
      ativa: "Ativa",
      inativa: "Inativa"
    }
  end

  def expense_type_label
    self.class.expense_type_labels[expense_type.to_sym] || expense_type
  end

  def category_label
    self.class.category_labels[category.to_sym] || category
  end

  def status_label
    self.class.status_labels[status.to_sym] || status
  end
end
