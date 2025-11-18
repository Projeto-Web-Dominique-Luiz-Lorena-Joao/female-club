class Sale < ApplicationRecord

  belongs_to :customer, optional: true
  belongs_to :employee
  has_many :sale_services, dependent: :destroy
  # has_many :sale_items, dependent: :destroy

  validates :sale_date, presence: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_percentage,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100,
              only_integer: true
            },
            allow_nil: true
  validates :payment_method, presence: true
  validates :status, presence: true, inclusion: { in: %w[pendente pago cancelado expirado] }

  enum :payment_method, {
    dinheiro: "dinheiro",
    cartao_credito: "cartao_credito",
    cartao_debito: "cartao_debito",
    pix: "pix",
    transferencia: "transferencia",
    boleto: "boleto"
   }

  enum :status, {
    pendente: "pendente",
    pago: "pago",
    cancelado: "cancelado",
    expirado: "expirado"
   }

  scope :recent, -> { order(sale_date: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :overdue, -> { where('due_date < ? AND status = ?', Date.today, 'pendente') }
  scope :by_period, ->(start_date, end_date) { where(sale_date: start_date..end_date) }
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :by_employee, ->(employee_id) { where(employee_id: employee_id) }

  before_validation :set_default_status, on: :create
  before_validation :set_default_payment_method, on: :create
  before_save :calculate_total_amount

  def overdue?
    due_date.present? && due_date < Date.today && pendente?
  end

  def days_overdue
    return 0 unless overdue?
    (Date.today - due_date).to_i
  end

  def total_with_discount
    discount_pct = (discount_percentage || 0).to_f / 100
    total_amount * (1 - discount_pct)
  end

  def mark_as_paid!
    update(status: 'pago', paid_date: Date.today)
  end

  def customer_name
    customer&.full_name || 'Cliente Avulso'
  end

  def employee_name
    employee.full_name
  end

  private

  def set_default_payment_method
    self.payment_method ||= 'pix'
  end

  def set_default_status
    self.status ||= 'pago'
  end

  def calculate_total_amount
    # Implementar lógica se necessário, baseado em sale_items
    # self.total_amount = sale_items.sum(&:subtotal)
  end
end