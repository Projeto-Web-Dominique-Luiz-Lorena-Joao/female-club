# frozen_string_literal: true

require "test_helper"

class ProductOutputTest < ActiveSupport::TestCase
  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar saída de produto com atributos válidos" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, quantity: 10)
    assert_valid output
  end

  test "deve exigir produto" do
    output = build(:product_output, product: nil)
    assert_invalid output, :product
  end

  test "deve exigir quantidade" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, quantity: nil)
    assert_invalid output, :quantity
  end

  test "quantidade deve ser maior que zero" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, quantity: 0)
    assert_invalid output, :quantity
  end

  test "quantidade não pode ser negativa" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, quantity: -5)
    assert_invalid output, :quantity
  end

  test "quantidade deve ser inteira" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, quantity: 10.5)
    assert_invalid output, :quantity
  end

  test "deve exigir tipo de saída" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, output_type: nil)
    assert_invalid output, :output_type
  end

  test "deve exigir data de saída" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, date_output: nil)
    assert_invalid output, :date_output
  end

  test "created_by é opcional" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, created_by: nil)
    assert_valid output
  end

  test "notes é opcional" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, notes: nil)
    assert_valid output
  end

  # ============================================
  # VALIDAÇÃO DE ESTOQUE SUFICIENTE
  # ============================================

  test "não permite saída maior que estoque disponível" do
    product = create(:product, :with_stock, initial_stock: 50)

    output = build(:product_output, product: product, quantity: 60)
    assert_not output.valid?
    # O erro pode estar em :quantity ou :base dependendo da implementação
    assert output.errors.any?, "Deveria ter erro de validação"
  end

  test "permite saída igual ao estoque disponível" do
    product = create(:product, :with_stock, initial_stock: 50)

    output = build(:product_output, product: product, quantity: 50)
    assert_valid output
  end

  test "permite saída menor que estoque disponível" do
    product = create(:product, :with_stock, initial_stock: 50)

    output = build(:product_output, product: product, quantity: 30)
    assert_valid output
  end

  test "não permite saída de produto sem estoque" do
    product = create(:product) # Sem entrada, estoque = 0

    output = build(:product_output, product: product, quantity: 1)
    assert_not output.valid?
    # O erro pode estar em :quantity ou :base dependendo da implementação
    assert output.errors.any?, "Deveria ter erro de validação para estoque insuficiente"
  end

  # ============================================
  # ENUMS
  # ============================================

  test "output_type enum tem valores corretos" do
    expected = %w[venda extravio perda dano tragedia_climatica devolucao outro]
    assert_equal expected, ProductOutput.output_types.keys
  end

  # ============================================
  # ASSOCIAÇÕES
  # ============================================

  test "pertence a produto" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product)

    assert_equal product, output.product
  end

  test "pertence a created_by (usuário)" do
    user = create(:user)
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, created_by: user)

    assert_equal user, output.created_by
  end

  # ============================================
  # IMPACTO NO ESTOQUE
  # ============================================

  test "criar saída reduz estoque do produto" do
    product = create(:product, :with_stock, initial_stock: 100)
    initial_quantity = product.quantity

    create(:product_output, product: product, quantity: 30)

    product.reload
    assert_equal initial_quantity - 30, product.quantity
  end

  test "múltiplas saídas reduzem estoque cumulativamente" do
    product = create(:product, :with_stock, initial_stock: 100)

    create(:product_output, product: product, quantity: 20)
    create(:product_output, product: product, quantity: 30)

    product.reload
    assert_equal 50, product.quantity
  end

  test "saída atualiza status de estoque do produto" do
    product = create(:product, min_stock: 10)
    create(:product_input, product: product, quantity: 50)
    product.reload
    product.update_stock_status!
    assert_equal "em_estoque", product.stock_status

    # Criar saída que deixe estoque crítico (50 - 45 = 5, que é <= min_stock 10)
    create(:product_output, product: product, quantity: 45)

    product.reload
    product.update_stock_status!
    # Com quantity 5 e min_stock 10, deve ser crítico
    assert_equal "critico", product.stock_status
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope recent ordena por data decrescente" do
    product = create(:product, :with_stock, initial_stock: 100)

    old_output = create(:product_output, product: product, quantity: 5, date_output: 10.days.ago)
    new_output = create(:product_output, product: product, quantity: 5, date_output: Date.current)

    result = ProductOutput.recent

    assert_equal new_output, result.first
  end

  test "scope by_product filtra por produto" do
    product1 = create(:product, :with_stock, initial_stock: 100)
    product2 = create(:product, :with_stock, initial_stock: 100)

    output1 = create(:product_output, product: product1)
    output2 = create(:product_output, product: product2)

    result = ProductOutput.by_product(product1.id)

    assert_includes result, output1
    assert_not_includes result, output2
  end

  test "scope by_output_type filtra por tipo de saída" do
    product = create(:product, :with_stock, initial_stock: 100)

    perda = create(:product_output, product: product, quantity: 5, output_type: :perda)
    venda = create(:product_output, product: product, quantity: 5, output_type: :venda)

    result = ProductOutput.by_output_type(:perda)

    assert_includes result, perda
    assert_not_includes result, venda
  end

  test "scope by_date_range filtra por período" do
    product = create(:product, :with_stock, initial_stock: 100)

    inside = create(:product_output, product: product, quantity: 5, date_output: 5.days.ago)
    outside = create(:product_output, product: product, quantity: 5, date_output: 15.days.ago)

    result = ProductOutput.by_date_range(10.days.ago, Date.current)

    assert_includes result, inside
    assert_not_includes result, outside
  end

  # ============================================
  # TIPOS DE SAÍDA
  # ============================================

  test "pode criar saída do tipo venda" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, output_type: :venda)

    assert output.venda?
  end

  test "pode criar saída do tipo perda" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, output_type: :perda)

    assert output.perda?
  end

  test "pode criar saída do tipo extravio" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, output_type: :extravio)

    assert output.extravio?
  end

  test "pode criar saída do tipo dano" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, output_type: :dano)

    assert output.dano?
  end

  test "pode criar saída do tipo devolução" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, output_type: :devolucao)

    assert output.devolucao?
  end

  # ============================================
  # MÉTODOS DE FORMATAÇÃO
  # ============================================

  test "output_type_labels retorna hash de labels" do
    labels = ProductOutput.output_type_labels
    assert_kind_of Hash, labels
    assert_equal "Venda", labels[:venda]
    assert_equal "Perda", labels[:perda]
    assert_equal "Extravio", labels[:extravio]
    assert_equal "Dano", labels[:dano]
    assert_equal "Tragédia Climática", labels[:tragedia_climatica]
    assert_equal "Devolução", labels[:devolucao]
    assert_equal "Outro", labels[:outro]
  end

  test "output_label retorna label traduzido" do
    product = create(:product, :with_stock, initial_stock: 100)

    output_venda = build(:product_output, product: product, output_type: :venda)
    assert_equal "Venda", output_venda.output_label

    output_perda = build(:product_output, product: product, output_type: :perda)
    assert_equal "Perda", output_perda.output_label
  end

  test "output_badge_class para venda" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, output_type: :venda)
    assert_equal "bg-green-100 text-green-800", output.output_badge_class
  end

  test "output_badge_class para extravio" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, output_type: :extravio)
    assert_equal "bg-orange-100 text-orange-800", output.output_badge_class
  end

  test "output_badge_class para perda" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, output_type: :perda)
    assert_equal "bg-red-100 text-red-800", output.output_badge_class
  end

  test "output_badge_class para dano" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, output_type: :dano)
    assert_equal "bg-yellow-100 text-yellow-800", output.output_badge_class
  end

  test "output_badge_class para tragedia_climatica" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, output_type: :tragedia_climatica)
    assert_equal "bg-purple-100 text-purple-800", output.output_badge_class
  end

  test "output_badge_class para devolucao" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, output_type: :devolucao)
    assert_equal "bg-blue-100 text-blue-800", output.output_badge_class
  end

  test "output_badge_class para outro" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = build(:product_output, product: product, output_type: :outro)
    assert_equal "bg-gray-100 text-gray-800", output.output_badge_class
  end

  # ============================================
  # VALIDAÇÃO DE ESTOQUE NA ATUALIZAÇÃO
  # ============================================

  test "não permite aumentar quantidade além do estoque disponível" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, quantity: 10)

    # Tentar aumentar para 150 (diferença de 140, mas só tem 90 disponíveis)
    output.quantity = 150
    assert_not output.valid?
  end

  test "permite reduzir quantidade da saída" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, quantity: 50)

    output.quantity = 30
    assert output.valid?
  end

  test "não permite alterar product_id para produto sem estoque suficiente" do
    product1 = create(:product, :with_stock, initial_stock: 100)
    product2 = create(:product, :with_stock, initial_stock: 10)

    output = create(:product_output, product: product1, quantity: 50)

    # Tentar mover para produto 2 que só tem 10 unidades
    output.product = product2
    assert_not output.valid?
    assert output.errors[:base].any?
  end

  test "permite alterar product_id para produto com estoque suficiente" do
    product1 = create(:product, :with_stock, initial_stock: 100)
    product2 = create(:product, :with_stock, initial_stock: 100)

    output = create(:product_output, product: product1, quantity: 50)

    # Mover para produto 2 que tem 100 unidades
    output.product = product2
    assert output.valid?
  end

  test "validação de atualização verifica diferença de quantidade corretamente" do
    product = create(:product, :with_stock, initial_stock: 100)
    output = create(:product_output, product: product, quantity: 50)

    # Agora só tem 50 no estoque. Tentar aumentar a saída para 80
    # Diferença é 30, e só tem 50 disponíveis, então deve passar
    output.quantity = 80
    assert output.valid?

    # Tentar aumentar para 200 (diferença de 150, mas só tem 50 disponíveis)
    output.quantity = 200
    assert_not output.valid?
  end
end
