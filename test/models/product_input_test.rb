# frozen_string_literal: true

require "test_helper"

class ProductInputTest < ActiveSupport::TestCase
  setup do
    @product = create(:product)
    @supplier = create(:supplier)
  end

  # Helper para criar input com produto pré-criado
  def build_input(**attrs)
    defaults = { product: @product }
    build(:product_input, **defaults.merge(attrs))
  end

  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar entrada de produto com atributos válidos" do
    input = build_input
    assert_valid input
  end

  test "deve exigir produto" do
    input = build_input(product: nil)
    assert_invalid input, :product
  end

  test "deve exigir quantidade" do
    input = build_input(quantity: nil)
    assert_invalid input, :quantity
  end

  test "quantidade deve ser maior que zero" do
    input = build_input(quantity: 0)
    assert_invalid input, :quantity
  end

  test "quantidade não pode ser negativa" do
    input = build_input(quantity: -5)
    assert_invalid input, :quantity
  end

  test "quantidade deve ser inteira" do
    input = build_input(quantity: 10.5)
    assert_invalid input, :quantity
  end

  test "deve exigir data de entrada" do
    input = build_input(date_input: nil)
    assert_invalid input, :date_input
  end

  test "unit_cost não pode ser negativo" do
    input = build_input(unit_cost: -10)
    assert_invalid input, :unit_cost
  end

  test "unit_cost pode ser zero" do
    input = build_input(unit_cost: 0)
    assert_valid input
  end

  test "unit_cost é opcional" do
    input = build_input(unit_cost: nil)
    assert_valid input
  end

  test "supplier é opcional" do
    input = build_input(supplier: nil)
    assert_valid input
  end

  test "created_by é opcional" do
    input = build_input(created_by: nil)
    assert_valid input
  end

  test "invoice_number é opcional" do
    input = build_input(invoice_number: nil)
    assert_valid input
  end

  # ============================================
  # ASSOCIAÇÕES
  # ============================================

  test "pertence a produto" do
    product = create(:product)
    input = create(:product_input, product: product)

    assert_equal product, input.product
  end

  test "pertence a fornecedor" do
    supplier = create(:supplier)
    input = create(:product_input, supplier: supplier)

    assert_equal supplier, input.supplier
  end

  test "pertence a created_by (usuário)" do
    user = create(:user)
    input = create(:product_input, created_by: user)

    assert_equal user, input.created_by
  end

  # ============================================
  # CÁLCULOS
  # ============================================

  test "total_cost calcula quantidade * custo unitário" do
    input = build_input(quantity: 10, unit_cost: 25.50)
    assert_equal 255.0, input.total_cost
  end

  test "total_cost retorna zero se unit_cost é nil" do
    input = build_input(quantity: 10, unit_cost: nil)
    assert_equal 0, input.total_cost
  end

  # ============================================
  # ATUALIZAÇÃO DO ESTOQUE DO PRODUTO
  # ============================================

  test "criar entrada aumenta estoque do produto" do
    product = create(:product)
    initial_quantity = product.quantity

    create(:product_input, product: product, quantity: 50)

    product.reload
    assert_equal initial_quantity + 50, product.quantity
  end

  test "múltiplas entradas acumulam estoque" do
    product = create(:product)

    create(:product_input, product: product, quantity: 30)
    create(:product_input, product: product, quantity: 20)

    product.reload
    assert_equal 50, product.quantity
  end

  test "atualizar quantidade da entrada ajusta estoque" do
    product = create(:product)
    input = create(:product_input, product: product, quantity: 50)

    product.reload
    assert_equal 50, product.quantity

    input.update!(quantity: 70)

    product.reload
    assert_equal 70, product.quantity
  end

  test "destruir entrada reduz estoque do produto" do
    product = create(:product)
    input = create(:product_input, product: product, quantity: 50)

    product.reload
    assert_equal 50, product.quantity

    input.destroy

    product.reload
    assert_equal 0, product.quantity
  end

  test "alterar product_id da entrada ajusta estoque de ambos os produtos" do
    product1 = create(:product)
    product2 = create(:product)

    # Criar entrada no produto 1
    input = create(:product_input, product: product1, quantity: 30)
    product1.reload
    assert_equal 30, product1.quantity

    # Alterar para produto 2
    input.update!(product: product2)

    product1.reload
    product2.reload

    # Produto 1 deve perder o estoque
    assert_equal 0, product1.quantity
    # Produto 2 deve ganhar o estoque
    assert_equal 30, product2.quantity
  end

  test "alterar product_id e quantidade ao mesmo tempo ajusta corretamente" do
    product1 = create(:product)
    product2 = create(:product)

    # Criar entrada no produto 1 com 40 unidades
    input = create(:product_input, product: product1, quantity: 40)
    product1.reload
    assert_equal 40, product1.quantity

    # Alterar para produto 2 com nova quantidade
    input.update!(product: product2, quantity: 60)

    product1.reload
    product2.reload

    # Produto 1 deve perder o estoque original
    assert_equal 0, product1.quantity
    # Produto 2 deve ganhar a nova quantidade
    assert_equal 60, product2.quantity
  end

  # ============================================
  # ATUALIZAÇÃO DO STATUS DE ESTOQUE
  # ============================================

  test "criar entrada atualiza status de estoque do produto" do
    product = create(:product, min_stock: 10)
    assert_equal "fora_de_estoque", product.stock_status

    create(:product_input, product: product, quantity: 100)

    product.reload
    assert_equal "em_estoque", product.stock_status
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope recent ordena por data decrescente" do
    old_input = create(:product_input, date_input: 10.days.ago)
    new_input = create(:product_input, date_input: Date.current)

    result = ProductInput.recent

    assert_equal new_input, result.first
  end

  test "scope by_product filtra por produto" do
    product1 = create(:product)
    product2 = create(:product)

    input1 = create(:product_input, product: product1)
    input2 = create(:product_input, product: product2)

    result = ProductInput.by_product(product1.id)

    assert_includes result, input1
    assert_not_includes result, input2
  end

  test "scope by_supplier filtra por fornecedor" do
    supplier1 = create(:supplier)
    supplier2 = create(:supplier)

    input1 = create(:product_input, supplier: supplier1)
    input2 = create(:product_input, supplier: supplier2)

    result = ProductInput.by_supplier(supplier1.id)

    assert_includes result, input1
    assert_not_includes result, input2
  end

  test "scope by_date_range filtra por período" do
    inside = create(:product_input, date_input: 5.days.ago)
    outside = create(:product_input, date_input: 15.days.ago)

    result = ProductInput.by_date_range(10.days.ago, Date.current)

    assert_includes result, inside
    assert_not_includes result, outside
  end
end
