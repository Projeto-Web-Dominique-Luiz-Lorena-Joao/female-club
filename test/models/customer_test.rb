# frozen_string_literal: true

require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar cliente com atributos válidos" do
    customer = build(:customer)
    assert_valid customer
  end

  test "deve exigir nome completo" do
    customer = build(:customer, full_name: nil)
    assert_invalid customer, :full_name
  end

  test "nome completo deve ter pelo menos 3 caracteres" do
    customer = build(:customer, full_name: "AB")
    assert_invalid customer, :full_name
  end

  test "nome completo com 3 caracteres é válido" do
    customer = build(:customer, full_name: "Ana")
    assert_valid customer
  end

  # ============================================
  # VALIDAÇÃO DE CPF
  # ============================================

  test "CPF deve ser único" do
    cpf = generate_valid_cpf
    create(:customer, cpf: cpf)

    customer = build(:customer, cpf: cpf)
    assert_invalid customer, :cpf
  end

  test "CPF inválido não é aceito" do
    customer = build(:customer, cpf: "12345678901")
    assert_invalid customer, :cpf
  end

  test "CPF válido é aceito" do
    customer = build(:customer, cpf: generate_valid_cpf)
    assert_valid customer
  end

  test "CPF nil é aceito" do
    customer = build(:customer, cpf: nil)
    assert_valid customer
  end

  # ============================================
  # VALIDAÇÃO DE EMAIL
  # ============================================

  test "email deve ser único" do
    create(:customer, email: "test@example.com")

    customer = build(:customer, email: "test@example.com")
    assert_invalid customer, :email
  end

  test "email duplicado com case diferente é inválido" do
    create(:customer, email: "test@example.com")

    customer = build(:customer, email: "TEST@EXAMPLE.COM")
    assert_invalid customer, :email
  end

  test "email com formato inválido não é aceito" do
    customer = build(:customer, email: "invalid-email")
    assert_invalid customer, :email
  end

  test "email válido é aceito" do
    customer = build(:customer, email: "valid@example.com")
    assert_valid customer
  end

  test "email nil é aceito" do
    customer = build(:customer, email: nil)
    assert_valid customer
  end

  # ============================================
  # VALIDAÇÃO DE TELEFONE
  # ============================================

  test "telefone com menos de 10 dígitos é inválido" do
    customer = build(:customer, phone_number: "123456789")
    assert_invalid customer, :phone_number
  end

  test "telefone com 10 dígitos é válido" do
    customer = build(:customer, phone_number: "1123456789")
    assert_valid customer
  end

  test "telefone com 11 dígitos é válido" do
    customer = build(:customer, phone_number: "11987654321")
    assert_valid customer
  end

  test "telefone nil é aceito" do
    customer = build(:customer, phone_number: nil)
    assert_valid customer
  end

  # ============================================
  # ASSOCIAÇÕES
  # ============================================

  test "pertence a fiador" do
    guarantor = create(:guarantor)
    customer = create(:customer, guarantor: guarantor)

    assert_equal guarantor, customer.guarantor
  end

  test "fiador é opcional" do
    customer = create(:customer, guarantor: nil)
    assert_nil customer.guarantor
  end

  test "tem muitas vendas" do
    customer = create(:customer)
    sale1 = create(:sale, customer: customer)
    sale2 = create(:sale, customer: customer)

    assert_includes customer.sales, sale1
    assert_includes customer.sales, sale2
  end

  test "tem muitos agendamentos" do
    customer = create(:customer)
    appointment1 = create(:service_appointment, customer: customer)
    appointment2 = create(:service_appointment, customer: customer)

    assert_includes customer.service_appointments, appointment1
    assert_includes customer.service_appointments, appointment2
  end

  test "destruir cliente destrói suas vendas" do
    customer = create(:customer)
    create(:sale, customer: customer)

    assert_difference "Sale.count", -1 do
      customer.destroy
    end
  end

  test "destruir cliente destrói seus agendamentos" do
    customer = create(:customer)
    create(:service_appointment, customer: customer)

    assert_difference "ServiceAppointment.count", -1 do
      customer.destroy
    end
  end

  # ============================================
  # MÉTODOS DE NEGÓCIO
  # ============================================

  test "total_purchases soma vendas não canceladas" do
    customer = create(:customer)
    create(:sale, customer: customer, total_amount: 100, status: :pago)
    create(:sale, customer: customer, total_amount: 150, status: :pago)
    create(:sale, customer: customer, total_amount: 50, status: :cancelado)

    assert_equal 250, customer.total_purchases
  end

  test "total_purchases retorna zero sem vendas" do
    customer = create(:customer)
    assert_equal 0, customer.total_purchases
  end

  test "last_purchase_date retorna data da última venda" do
    customer = create(:customer)
    create(:sale, customer: customer, sale_date: 10.days.ago)
    last_sale = create(:sale, customer: customer, sale_date: 2.days.ago)

    assert_equal last_sale.sale_date, customer.last_purchase_date
  end

  test "last_purchase_date retorna nil sem vendas" do
    customer = create(:customer)
    assert_nil customer.last_purchase_date
  end

  test "purchases_count conta apenas vendas não canceladas" do
    customer = create(:customer)
    create(:sale, customer: customer, status: :pago)
    create(:sale, customer: customer, status: :pago)
    create(:sale, customer: customer, status: :cancelado)

    assert_equal 2, customer.purchases_count
  end

  test "age calcula idade corretamente" do
    customer = create(:customer, birth_date: 30.years.ago.to_date)
    assert_equal 30, customer.age
  end

  test "age retorna nil sem data de nascimento" do
    customer = build(:customer, birth_date: nil)
    assert_nil customer.age
  end

  # ============================================
  # FORMATAÇÃO
  # ============================================

  test "formatted_cpf retorna CPF formatado" do
    customer = build(:customer, cpf: "52998224725")
    assert_equal "529.982.247-25", customer.formatted_cpf
  end

  test "formatted_cpf retorna traço para CPF nil" do
    customer = build(:customer, cpf: nil)
    assert_equal "-", customer.formatted_cpf
  end

  test "formatted_phone retorna telefone formatado" do
    customer = build(:customer, phone_number: "11987654321")
    assert_match(/\(\d{2}\)\s*\d{4,5}-\d{4}/, customer.formatted_phone)
  end

  test "formatted_birth_date retorna data formatada" do
    customer = build(:customer, birth_date: Date.new(1990, 5, 15))
    # O método usa I18n.l que pode retornar diferentes formatos
    formatted = customer.formatted_birth_date
    assert formatted.present?
    assert_not_equal "-", formatted
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope recent ordena por data de criação decrescente" do
    old = create(:customer)
    new = create(:customer)

    result = Customer.recent

    assert_equal new, result.first
    assert_equal old, result.last
  end
end
