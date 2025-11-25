class Sale < ApplicationRecord

  belongs_to :customer, optional: true
  belongs_to :employee
  has_many :sale_services, dependent: :destroy
  has_many :sale_products, dependent: :destroy
  has_many :products, through: :sale_products
  has_many :stock_movements, dependent: :destroy
  has_many :services, through: :sale_services

  accepts_nested_attributes_for :sale_products, allow_destroy: true, reject_if: :reject_product
  accepts_nested_attributes_for :sale_services, allow_destroy: true, reject_if: :reject_service

  validates :sale_date, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, presence: true
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
  after_commit :create_product_outputs, on: :create

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

  def create_product_outputs
    sale_products.each do |sale_product|
      ProductOutput.create(
        product_id: sale_product.product_id,
        quantity: sale_product.quantity,
        output_type: 'venda',
        date_output: sale_date,
        created_by_id: nil
      )
    end
  end

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

  def reject_product(attributes)
    # Reject if product_id is blank (unless it's marked for destruction)
    should_reject = attributes['product_id'].blank? && attributes['_destroy'].to_s != '1'
    Rails.logger.info "REJECT PRODUCT: product_id=#{attributes['product_id']&.inspect}, _destroy=#{attributes['_destroy']&.inspect}, should_reject=#{should_reject}"
    should_reject
  end

  def reject_service(attributes)
    # Reject if service_id is blank (unless it's marked for destruction)
    should_reject = attributes['service_id'].blank? && attributes['_destroy'].to_s != '1'
    Rails.logger.info "REJECT SERVICE: service_id=#{attributes['service_id']&.inspect}, _destroy=#{attributes['_destroy']&.inspect}, should_reject=#{should_reject}"
    should_reject
  end
end
