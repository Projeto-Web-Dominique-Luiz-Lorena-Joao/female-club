# frozen_string_literal: true

require "test_helper"

class GuarantorTest < ActiveSupport::TestCase
  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar fiador com atributos válidos" do
    guarantor = build(:guarantor)
    assert_valid guarantor
  end

  test "deve exigir nome completo" do
    guarantor = build(:guarantor, full_name: nil)
    assert_invalid guarantor, :full_name
  end

  test "nome completo deve ter pelo menos 3 caracteres" do
    guarantor = build(:guarantor, full_name: "AB")
    assert_invalid guarantor, :full_name
  end

  test "nome completo deve ter no máximo 100 caracteres" do
    guarantor = build(:guarantor, full_name: "A" * 101)
    assert_invalid guarantor, :full_name
  end

  test "CPF deve ser único quando presente" do
    cpf = generate_valid_cpf
    create(:guarantor, cpf: cpf)

    guarantor = build(:guarantor, cpf: cpf)
    assert_invalid guarantor, :cpf
  end

  test "CPF pode ser nil" do
    guarantor = build(:guarantor, cpf: nil)
    assert_valid guarantor
  end

  test "CPF inválido não é aceito" do
    guarantor = build(:guarantor, cpf: "12345678901")
    assert_invalid guarantor, :cpf
  end

  test "telefone deve ter 10 ou 11 dígitos" do
    guarantor_10 = build(:guarantor, phone: "1134567890")
    assert_valid guarantor_10

    guarantor_11 = build(:guarantor, phone: "11987654321")
    assert_valid guarantor_11

    guarantor_invalid = build(:guarantor, phone: "123456789")
    assert_invalid guarantor_invalid, :phone
  end

  test "telefone pode ser nil" do
    guarantor = build(:guarantor, phone: nil)
    assert_valid guarantor
  end

  test "status padrão é ativo" do
    guarantor = Guarantor.new
    assert_equal "ativo", guarantor.status
  end

  test "status inválido não é aceito" do
    guarantor = build(:guarantor)
    assert_raises(ArgumentError) do
      guarantor.status = "invalido"
    end
  end

  # ============================================
  # ENUMS
  # ============================================

  test "relationship enum tem valores corretos" do
    expected = %w[pai mae irmao esposo avo tio primo amigo outro]
    assert_equal expected, Guarantor.relationships.keys
  end

  test "status enum tem valores corretos" do
    expected = %w[ativo inativo]
    assert_equal expected, Guarantor.statuses.keys
  end

  # ============================================
  # ASSOCIAÇÕES
  # ============================================

  test "tem um cliente" do
    guarantor = create(:guarantor)
    customer = create(:customer, guarantor: guarantor)

    assert_equal customer, guarantor.customer
  end

  test "destruir fiador nullifica cliente" do
    guarantor = create(:guarantor)
    customer = create(:customer, guarantor: guarantor)

    guarantor.destroy

    customer.reload
    assert_nil customer.guarantor_id
  end

  # ============================================
  # FORMATAÇÃO
  # ============================================

  test "formatted_cpf formata CPF corretamente" do
    guarantor = create(:guarantor, cpf: generate_valid_cpf)
    formatted = guarantor.formatted_cpf

    assert formatted.present?
    assert_match(/\d{3}\.\d{3}\.\d{3}-\d{2}/, formatted)
  end

  test "formatted_cpf retorna nil para CPF vazio" do
    guarantor = build(:guarantor, cpf: nil)
    assert_nil guarantor.formatted_cpf
  end

  test "formatted_phone formata celular com 11 dígitos" do
    guarantor = create(:guarantor, phone: "11987654321")
    assert_equal "(11) 98765-4321", guarantor.formatted_phone
  end

  test "formatted_phone formata telefone fixo com 10 dígitos" do
    guarantor = create(:guarantor, phone: "1134567890")
    assert_equal "(11) 3456-7890", guarantor.formatted_phone
  end

  test "formatted_phone retorna original para outros tamanhos" do
    guarantor = build(:guarantor)
    guarantor.phone = "123456789012"  # 12 dígitos
    # Não passa validação, mas o método deve retornar o valor
    assert_equal "123456789012", guarantor.formatted_phone
  end

  test "formatted_phone retorna nil para phone vazio" do
    guarantor = build(:guarantor, phone: nil)
    assert_nil guarantor.formatted_phone
  end

  # ============================================
  # CALLBACKS DE NORMALIZAÇÃO
  # ============================================

  test "normaliza CPF removendo caracteres especiais" do
    guarantor = create(:guarantor, cpf: "529.982.247-25")
    assert_equal "52998224725", guarantor.cpf
  end

  test "normaliza CPF vazio para nil" do
    guarantor = build(:guarantor, cpf: "")
    guarantor.valid?
    assert_nil guarantor.cpf
  end

  test "normaliza phone removendo caracteres especiais" do
    guarantor = create(:guarantor, phone: "(11) 98765-4321")
    assert_equal "11987654321", guarantor.phone
  end

  test "normaliza phone vazio para nil" do
    guarantor = build(:guarantor, phone: "")
    guarantor.valid?
    assert_nil guarantor.phone
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope with_cpf retorna fiadores com CPF" do
    with_cpf = create(:guarantor, cpf: generate_valid_cpf)
    without_cpf = create(:guarantor, cpf: nil)

    result = Guarantor.with_cpf

    assert_includes result, with_cpf
    assert_not_includes result, without_cpf
  end

  test "scope with_phone retorna fiadores com telefone" do
    with_phone = create(:guarantor, phone: "11987654321")
    without_phone = create(:guarantor, phone: nil)

    result = Guarantor.with_phone

    assert_includes result, with_phone
    assert_not_includes result, without_phone
  end

  test "scope by_relationship filtra por relacionamento" do
    pai = create(:guarantor, relationship: :pai)
    mae = create(:guarantor, relationship: :mae)

    result = Guarantor.by_relationship(:pai)

    assert_includes result, pai
    assert_not_includes result, mae
  end

  test "scope recent ordena por data de criação decrescente" do
    old = create(:guarantor)
    new = create(:guarantor)

    result = Guarantor.recent

    assert_equal new, result.first
    assert_equal old, result.last
  end
end
