require "test_helper"

class SaleProductTest < ActiveSupport::TestCase
  def setup
    @sale = Sale.create!(
      sale_date: Date.today,
      total_amount: 100.00,
      payment_method: 'pix',
      status: 'pago',
      employee_id: employees(:one).id
    )
    @product = Product.create!(
      name: "Produto Teste",
      price: 50.00,
      active: true
    )
  end

  test "should create a sale product with valid attributes" do
    sale_product = SaleProduct.new(
      sale: @sale,
      product: @product,
      quantity: 2,
      unit_price: 50.00
    )
    assert sale_product.save
  end

  test "should validate presence of quantity" do
    sale_product = SaleProduct.new(
      sale: @sale,
      product: @product,
      quantity: nil,
      unit_price: 50.00
    )
    assert_not sale_product.save
    assert_includes sale_product.errors[:quantity], "can't be blank"
  end

  test "should validate quantity is integer" do
    sale_product = SaleProduct.new(
      sale: @sale,
      product: @product,
      quantity: 1.5,
      unit_price: 50.00
    )
    assert_not sale_product.save
  end

  test "should validate quantity is greater than 0" do
    sale_product = SaleProduct.new(
      sale: @sale,
      product: @product,
      quantity: 0,
      unit_price: 50.00
    )
    assert_not sale_product.save
  end

  test "should validate presence of unit_price" do
    sale_product = SaleProduct.new(
      sale: @sale,
      product: @product,
      quantity: 2,
      unit_price: nil
    )
    assert_not sale_product.save
    assert_includes sale_product.errors[:unit_price], "can't be blank"
  end

  test "should calculate total price correctly" do
    sale_product = SaleProduct.create!(
      sale: @sale,
      product: @product,
      quantity: 3,
      unit_price: 25.50
    )
    assert_equal 76.50, sale_product.total_price
  end
end
