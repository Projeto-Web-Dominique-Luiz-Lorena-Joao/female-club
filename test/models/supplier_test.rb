# frozen_string_literal: true

require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar fornecedor com atributos válidos" do
    supplier = build(:supplier)
    assert_valid supplier
  end

  test "deve exigir legal_name" do
    supplier = build(:supplier, legal_name: nil)
    assert_invalid supplier, :legal_name
  end

  test "legal_name deve ter pelo menos 3 caracteres" do
    supplier = build(:supplier, legal_name: "AB")
    assert_invalid supplier, :legal_name
  end

  test "legal_name com 3 caracteres é válido" do
    supplier = build(:supplier, legal_name: "ABC")
    assert_valid supplier
  end

  test "email deve ser válido quando presente" do
    supplier = build(:supplier, email: "invalid-email")
    assert_invalid supplier, :email
  end

  test "email válido é aceito" do
    supplier = build(:supplier, email: "supplier@example.com")
    assert_valid supplier
  end

  test "email em branco é aceito" do
    supplier = build(:supplier, email: nil)
    assert_valid supplier
  end

  test "email deve ser único" do
    create(:supplier, email: "supplier@test.com")
    supplier = build(:supplier, email: "supplier@test.com")
    assert_invalid supplier, :email
  end

  # ============================================
  # ENUMS
  # ============================================

  test "status enum tem valores corretos" do
    expected = %w[ativo inativo]
    assert_equal expected, Supplier.statuses.keys
  end

  test "product_category enum tem valores corretos" do
    expected = %w[cosmeticos maquiagem perfumaria cabelo unhas pele acessorios equipamentos diversos]
    assert_equal expected, Supplier.product_categories.keys
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope active retorna apenas fornecedores ativos" do
    active = create(:supplier, status: :ativo)
    inactive = create(:supplier, status: :inativo)

    result = Supplier.active

    assert_includes result, active
    assert_not_includes result, inactive
  end

  test "scope inactive retorna apenas fornecedores inativos" do
    active = create(:supplier, status: :ativo)
    inactive = create(:supplier, status: :inativo)

    result = Supplier.inactive

    assert_not_includes result, active
    assert_includes result, inactive
  end

  test "scope recent ordena por data de criação decrescente" do
    old = create(:supplier)
    new = create(:supplier)

    result = Supplier.recent

    assert_equal new, result.first
    assert_equal old, result.last
  end

  test "scope by_category filtra por categoria" do
    cosmeticos = create(:supplier, product_category: :cosmeticos)
    maquiagem = create(:supplier, product_category: :maquiagem)

    result = Supplier.by_category(:cosmeticos)

    assert_includes result, cosmeticos
    assert_not_includes result, maquiagem
  end

  test "scope by_category ignora filtro se categoria vazia" do
    cosmeticos = create(:supplier, product_category: :cosmeticos)
    maquiagem = create(:supplier, product_category: :maquiagem)

    result = Supplier.by_category(nil)

    assert_includes result, cosmeticos
    assert_includes result, maquiagem
  end

  # ============================================
  # MÉTODOS DE INSTÂNCIA
  # ============================================

  test "display_name retorna trade_name quando presente" do
    supplier = build(:supplier, legal_name: "Razão Social", trade_name: "Nome Fantasia")
    assert_equal "Nome Fantasia", supplier.display_name
  end

  test "display_name retorna legal_name quando trade_name ausente" do
    supplier = build(:supplier, legal_name: "Razão Social", trade_name: nil)
    assert_equal "Razão Social", supplier.display_name
  end

  test "display_name retorna legal_name quando trade_name em branco" do
    supplier = build(:supplier, legal_name: "Razão Social", trade_name: "")
    assert_equal "Razão Social", supplier.display_name
  end

  test "formatted_phone retorna telefone formatado" do
    supplier = build(:supplier, phone_number: "11987654321")
    assert_equal "(11) 98765-4321", supplier.formatted_phone
  end

  test "formatted_phone retorna traço quando telefone ausente" do
    supplier = build(:supplier, phone_number: nil)
    assert_equal "-", supplier.formatted_phone
  end

  test "formatted_phone retorna traço quando telefone em branco" do
    supplier = build(:supplier, phone_number: "")
    assert_equal "-", supplier.formatted_phone
  end

  # ============================================
  # BADGES DE CATEGORIA
  # ============================================

  test "category_badge_color para cosmeticos" do
    supplier = build(:supplier, product_category: :cosmeticos)
    assert_equal "bg-pink-100 text-pink-800", supplier.category_badge_color
  end

  test "category_badge_color para maquiagem" do
    supplier = build(:supplier, product_category: :maquiagem)
    assert_equal "bg-purple-100 text-purple-800", supplier.category_badge_color
  end

  test "category_badge_color para perfumaria" do
    supplier = build(:supplier, product_category: :perfumaria)
    assert_equal "bg-blue-100 text-blue-800", supplier.category_badge_color
  end

  test "category_badge_color para cabelo" do
    supplier = build(:supplier, product_category: :cabelo)
    assert_equal "bg-orange-100 text-orange-800", supplier.category_badge_color
  end

  test "category_badge_color para unhas" do
    supplier = build(:supplier, product_category: :unhas)
    assert_equal "bg-red-100 text-red-800", supplier.category_badge_color
  end

  test "category_badge_color para pele" do
    supplier = build(:supplier, product_category: :pele)
    assert_equal "bg-yellow-100 text-yellow-800", supplier.category_badge_color
  end

  test "category_badge_color para acessorios" do
    supplier = build(:supplier, product_category: :acessorios)
    assert_equal "bg-indigo-100 text-indigo-800", supplier.category_badge_color
  end

  test "category_badge_color para equipamentos" do
    supplier = build(:supplier, product_category: :equipamentos)
    assert_equal "bg-gray-200 text-gray-800", supplier.category_badge_color
  end

  test "category_badge_color para diversos" do
    supplier = build(:supplier, product_category: :diversos)
    assert_equal "bg-gray-100 text-gray-800", supplier.category_badge_color
  end

  test "category_badge_color para categoria nil" do
    supplier = build(:supplier, product_category: nil)
    assert_equal "bg-gray-100 text-gray-800", supplier.category_badge_color
  end

  # ============================================
  # BADGES DE STATUS
  # ============================================

  test "status_badge_color para ativo" do
    supplier = build(:supplier, status: :ativo)
    assert_equal "bg-green-100 text-green-800", supplier.status_badge_color
  end

  test "status_badge_color para inativo" do
    supplier = build(:supplier, status: :inativo)
    assert_equal "bg-red-100 text-red-800", supplier.status_badge_color
  end

  # ============================================
  # ASSOCIAÇÕES
  # ============================================

  test "tem muitas expenses" do
    supplier = create(:supplier)
    expense = create(:expense, supplier: supplier)

    assert_includes supplier.expenses, expense
  end

  test "destruir fornecedor destrói suas expenses" do
    supplier = create(:supplier)
    create(:expense, supplier: supplier)

    assert_difference "Expense.count", -1 do
      supplier.destroy
    end
  end
end
