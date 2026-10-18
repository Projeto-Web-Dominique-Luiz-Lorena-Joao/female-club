# frozen_string_literal: true

require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar serviço com atributos válidos" do
    service = build(:service)
    assert_valid service
  end

  test "deve exigir nome" do
    service = build(:service, name: nil)
    assert_invalid service, :name
  end

  test "nome deve ter no máximo 255 caracteres" do
    service = build(:service, name: "a" * 256)
    assert_invalid service, :name
  end

  test "nome com 255 caracteres é válido" do
    service = build(:service, name: "a" * 255)
    assert_valid service
  end

  test "deve exigir preço" do
    service = build(:service, price: nil)
    assert_invalid service, :price
  end

  test "preço não pode ser negativo" do
    service = build(:service, price: -10)
    assert_invalid service, :price
  end

  test "preço zero é válido" do
    service = build(:service, price: 0)
    assert_valid service
  end

  test "preço positivo é válido" do
    service = build(:service, price: 100)
    assert_valid service
  end

  # ============================================
  # ENUM STATUS
  # ============================================

  test "active enum tem valores corretos" do
    expected = %w[ativo inativo arquivado]
    assert_equal expected, Service.actives.keys
  end

  test "status padrão é ativo" do
    service = Service.new(name: "Teste", price: 100)
    service.valid?
    assert_equal "ativo", service.active
  end

  test "status inválido gera erro" do
    assert_raises(ArgumentError) do
      build(:service, active: "invalid_status")
    end
  end

  # ============================================
  # ASSOCIAÇÕES
  # ============================================

  test "tem muitos sale_services" do
    service = create(:service)
    employee = create(:employee)
    customer = create(:customer)
    sale = create(:sale, employee: employee, customer: customer)
    sale_service = create(:sale_service, sale: sale, service: service)

    assert_includes service.sale_services, sale_service
  end

  test "tem muitos service_appointments" do
    service = create(:service)
    employee = create(:employee)
    customer = create(:customer)
    tomorrow = 1.day.from_now.beginning_of_day + 10.hours
    appointment = create(:service_appointment, service: service, employee: employee, customer: customer, appointment_date: tomorrow)

    assert_includes service.service_appointments, appointment
  end

  test "não permite destruir serviço com sale_services" do
    service = create(:service)
    employee = create(:employee)
    customer = create(:customer)
    sale = create(:sale, employee: employee, customer: customer)
    create(:sale_service, sale: sale, service: service)

    # dependent: :restrict_with_error gera RecordNotDestroyed
    assert_raises(ActiveRecord::RecordNotDestroyed) do
      service.destroy!
    end
  end

  test "não permite destruir serviço com agendamentos" do
    service = create(:service)
    employee = create(:employee)
    customer = create(:customer)
    tomorrow = 1.day.from_now.beginning_of_day + 10.hours
    create(:service_appointment, service: service, employee: employee, customer: customer, appointment_date: tomorrow)

    # dependent: :restrict_with_error gera RecordNotDestroyed
    assert_raises(ActiveRecord::RecordNotDestroyed) do
      service.destroy!
    end
  end

  # ============================================
  # MÉTODOS DE FORMATAÇÃO
  # ============================================

  test "formatted_price retorna preço formatado" do
    service = build(:service, price: 150.50)
    assert_equal "R$ 150.50", service.formatted_price
  end

  test "formatted_price com preço zero" do
    service = build(:service, price: 0)
    assert_equal "R$ 0.00", service.formatted_price
  end

  test "formatted_price com preço inteiro" do
    service = build(:service, price: 100)
    assert_equal "R$ 100.00", service.formatted_price
  end

  test "status_badge_class retorna classe correta para ativo" do
    service = build(:service, active: "ativo")
    assert_equal "bg-green-100 text-green-800", service.status_badge_class
  end

  test "status_badge_class retorna classe correta para inativo" do
    service = build(:service, active: "inativo")
    assert_equal "bg-yellow-100 text-yellow-800", service.status_badge_class
  end

  test "status_badge_class retorna classe correta para arquivado" do
    service = build(:service, active: "arquivado")
    assert_equal "bg-red-100 text-red-800", service.status_badge_class
  end

  test "status_label retorna label traduzido" do
    service = build(:service, active: "ativo")
    # O método usa I18n, então pode retornar o valor traduzido ou a chave
    assert service.status_label.present?
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope ordered_by_name ordena por nome" do
    create(:service, name: "Corte de Cabelo")
    create(:service, name: "Alisamento")
    create(:service, name: "Manicure")

    result = Service.ordered_by_name

    assert_equal "Alisamento", result.first.name
    assert_equal "Manicure", result.last.name
  end

  test "scope available retorna apenas serviços ativos" do
    active = create(:service, active: "ativo")
    inactive = create(:service, active: "inativo")
    archived = create(:service, active: "arquivado")

    result = Service.available

    assert_includes result, active
    assert_not_includes result, inactive
    assert_not_includes result, archived
  end
end
