require "test_helper"

class SaleServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = true

  def setup
    # Disable fixture loading for this test
    @employee = Employee.find_or_create_by!(full_name: 'Test Employee', cpf: '55555555555', position: 'gerente', salary: 2000, phone: '11999999999')
    @sale = Sale.create!(sale_date: Date.today, total_amount: 100, payment_method: 'pix', status: 'pago', employee: @employee)
    @service = Service.create!(name: 'Corte de Cabelo', price: 50, active: 'ativo')
  end

  test "should create sale_service with valid attributes" do
    sale_service = SaleService.create!(
      sale: @sale,
      service: @service,
      quantity: 2,
      unit_price: 50.00
    )

    assert sale_service.persisted?
    assert_equal 2, sale_service.quantity
    assert_equal 50.00, sale_service.unit_price
  end

  test "should calculate total_price correctly" do
    sale_service = SaleService.create!(
      sale: @sale,
      service: @service,
      quantity: 3,
      unit_price: 25.00
    )

    assert_equal 75.00, sale_service.total_price
  end

  test "should require quantity" do
    sale_service = SaleService.build(
      sale: @sale,
      service: @service,
      quantity: nil,
      unit_price: 50.00
    )

    assert_not sale_service.valid?
    assert sale_service.errors[:quantity].present?
  end

  test "should require unit_price" do
    sale_service = SaleService.build(
      sale: @sale,
      service: @service,
      quantity: 1,
      unit_price: nil
    )

    assert_not sale_service.valid?
    assert sale_service.errors[:unit_price].present?
  end
end
