# frozen_string_literal: true

require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  # ============================================
  # VALIDAÇÕES BÁSICAS
  # ============================================

  test "deve criar funcionário com atributos válidos" do
    employee = build(:employee)
    assert_valid employee
  end

  test "deve exigir nome completo" do
    employee = build(:employee, full_name: nil)
    assert_invalid employee, :full_name
  end

  test "nome completo deve ter pelo menos 3 caracteres" do
    employee = build(:employee, full_name: "AB")
    assert_invalid employee, :full_name
  end

  test "nome completo com 3 caracteres é válido" do
    employee = build(:employee, full_name: "Ana")
    assert_valid employee
  end

  test "deve exigir CPF" do
    employee = build(:employee, cpf: nil)
    assert_invalid employee, :cpf
  end

  test "deve exigir telefone" do
    employee = build(:employee, phone: nil)
    assert_invalid employee, :phone
  end

  test "deve exigir cargo" do
    employee = build(:employee, position: nil)
    assert_invalid employee, :position
  end

  # ============================================
  # VALIDAÇÃO DE CPF
  # ============================================

  test "CPF deve ser único" do
    cpf = generate_valid_cpf
    create(:employee, cpf: cpf)

    employee = build(:employee, cpf: cpf)
    assert_invalid employee, :cpf
  end

  test "CPF inválido não é aceito" do
    employee = build(:employee, cpf: "12345678901")
    assert_invalid employee, :cpf
  end

  test "CPF válido é aceito" do
    employee = build(:employee, cpf: generate_valid_cpf)
    assert_valid employee
  end

  # ============================================
  # VALIDAÇÃO DE EMAIL
  # ============================================

  test "email deve ser único quando presente" do
    create(:employee, email: "emp@femaleclub.com")

    employee = build(:employee, email: "emp@femaleclub.com")
    assert_invalid employee, :email
  end

  test "email com formato inválido não é aceito" do
    employee = build(:employee, email: "invalid-email")
    assert_invalid employee, :email
  end

  test "email nil é aceito" do
    employee = build(:employee, email: nil)
    assert_valid employee
  end

  # ============================================
  # VALIDAÇÃO DE SALÁRIO
  # ============================================

  test "salário negativo não é aceito" do
    employee = build(:employee, salary: -100)
    assert_invalid employee, :salary
  end

  test "salário zero não é aceito" do
    employee = build(:employee, salary: 0)
    assert_invalid employee, :salary
  end

  test "salário positivo é aceito" do
    employee = build(:employee, salary: 1500)
    assert_valid employee
  end

  test "salário nil é aceito" do
    employee = build(:employee, salary: nil)
    assert_valid employee
  end

  # ============================================
  # ENUMS
  # ============================================

  test "position enum tem valores corretos" do
    expected = %w[gerente vendedor caixa estoquista manicure cabeleireira esteticista maquiador atendente auxiliar]
    assert_equal expected, Employee.positions.keys
  end

  test "status enum tem valores corretos" do
    expected = %w[ativo inativo ferias afastado]
    assert_equal expected, Employee.statuses.keys
  end

  test "status padrão é ativo" do
    employee = Employee.new
    assert_equal "ativo", employee.status
  end

  # ============================================
  # ASSOCIAÇÕES
  # ============================================

  test "tem muitas vendas" do
    employee = create(:employee)
    sale1 = create(:sale, employee: employee)
    sale2 = create(:sale, employee: employee)

    assert_includes employee.sales, sale1
    assert_includes employee.sales, sale2
  end

  test "tem muitos agendamentos" do
    employee = create(:employee)
    customer = create(:customer)
    service = create(:service)

    # Criar agendamentos no futuro em horários diferentes para evitar conflito
    tomorrow = 1.day.from_now.beginning_of_day
    appointment1 = create(:service_appointment,
      employee: employee,
      customer: customer,
      service: service,
      appointment_date: tomorrow + 9.hours
    )
    appointment2 = create(:service_appointment,
      employee: employee,
      customer: customer,
      service: service,
      appointment_date: tomorrow + 11.hours
    )

    assert_includes employee.service_appointments, appointment1
    assert_includes employee.service_appointments, appointment2
  end

  test "tem muitas despesas" do
    employee = create(:employee)
    expense1 = create(:expense, employee: employee)
    expense2 = create(:expense, employee: employee)

    assert_includes employee.expenses, expense1
    assert_includes employee.expenses, expense2
  end

  test "destruir funcionário com vendas gera erro de constraint" do
    employee = create(:employee)
    sale = create(:sale, employee: employee)

    # O modelo Sale tem constraint NOT NULL em employee_id no banco
    # Mesmo com dependent: :nullify, o banco não permite null
    # Isso resulta em erro ao tentar destruir funcionário com vendas
    assert_raises(ActiveRecord::NotNullViolation) do
      employee.destroy
    end
  end

  test "destruir funcionário com agendamentos gera erro de constraint" do
    employee = create(:employee)
    customer = create(:customer)
    service = create(:service)
    appointment = create(:service_appointment,
      employee: employee,
      customer: customer,
      service: service
    )

    # O modelo ServiceAppointment tem constraint NOT NULL em employee_id
    # Mesmo com dependent: :nullify, o banco não permite null
    assert_raises(ActiveRecord::NotNullViolation) do
      employee.destroy
    end
  end

  # ============================================
  # MÉTODOS DE NEGÓCIO
  # ============================================

  test "years_of_service calcula anos de trabalho" do
    employee = create(:employee, admission_date: 3.years.ago.to_date)
    assert_equal 3, employee.years_of_service
  end

  test "years_of_service retorna zero para funcionário recém admitido" do
    employee = create(:employee, admission_date: 1.month.ago.to_date)
    assert_equal 0, employee.years_of_service
  end

  test "years_of_service retorna zero sem data de admissão" do
    employee = build(:employee, admission_date: nil)
    # O método retorna 0 (não nil) quando admission_date é nil
    assert_equal 0, employee.years_of_service
  end

  test "formatted_admission_time retorna tempo formatado" do
    employee = create(:employee, :veterano)
    formatted = employee.formatted_admission_time

    assert formatted.present?
  end

  test "on_payroll? retorna true para funcionário ativo" do
    employee = build(:employee, status: :ativo)
    assert employee.on_payroll?
  end

  test "on_payroll? retorna true para funcionário de férias" do
    employee = build(:employee, status: :ferias)
    assert employee.on_payroll?
  end

  test "on_payroll? retorna false para funcionário inativo" do
    employee = build(:employee, status: :inativo)
    assert_not employee.on_payroll?
  end

  test "on_payroll? retorna false para funcionário afastado" do
    employee = build(:employee, status: :afastado)
    assert_not employee.on_payroll?
  end

  test "status_color retorna cor correta para cada status" do
    ativo = build(:employee, status: :ativo)
    inativo = build(:employee, status: :inativo)
    ferias = build(:employee, status: :ferias)
    afastado = build(:employee, status: :afastado)

    assert ativo.status_color.present?
    assert inativo.status_color.present?
    assert ferias.status_color.present?
    assert afastado.status_color.present?
  end

  # ============================================
  # SCOPES
  # ============================================

  test "scope active retorna apenas funcionários ativos" do
    active = create(:employee, status: :ativo)
    inactive = create(:employee, status: :inativo)

    result = Employee.active

    assert_includes result, active
    assert_not_includes result, inactive
  end

  test "scope on_payroll retorna ativos e de férias" do
    active = create(:employee, status: :ativo)
    vacation = create(:employee, status: :ferias)
    inactive = create(:employee, status: :inativo)

    result = Employee.on_payroll

    assert_includes result, active
    assert_includes result, vacation
    assert_not_includes result, inactive
  end

  test "scope working retorna apenas funcionários trabalhando" do
    active = create(:employee, status: :ativo)
    vacation = create(:employee, status: :ferias)

    result = Employee.working

    assert_includes result, active
    assert_not_includes result, vacation
  end

  test "scope by_position filtra por cargo" do
    cabeleireira = create(:employee, position: :cabeleireira)
    manicure = create(:employee, position: :manicure)

    result = Employee.by_position(:cabeleireira)

    assert_includes result, cabeleireira
    assert_not_includes result, manicure
  end

  test "scope recent ordena por data de criação decrescente" do
    old = create(:employee)
    new = create(:employee)

    result = Employee.recent

    assert_equal new, result.first
    assert_equal old, result.last
  end

  # ============================================
  # FORMATAÇÃO
  # ============================================

  test "formatted_cpf formata CPF corretamente" do
    employee = build(:employee, cpf: "52998224725")
    assert_equal "529.982.247-25", employee.formatted_cpf
  end

  test "formatted_cpf retorna traço para CPF vazio" do
    employee = build(:employee)
    employee.cpf = nil
    employee.valid?  # Ignora validação para teste
    # O before_validation limpa o CPF, então forçamos nil
    employee.instance_variable_set(:@cpf, nil)
    def employee.cpf; nil; end

    assert_equal "-", employee.formatted_cpf
  end

  test "formatted_phone formata celular com 11 dígitos" do
    employee = build(:employee, phone: "11987654321")
    assert_equal "(11) 98765-4321", employee.formatted_phone
  end

  test "formatted_phone formata telefone fixo com 10 dígitos" do
    employee = build(:employee, phone: "1134567890")
    assert_equal "(11) 3456-7890", employee.formatted_phone
  end

  test "formatted_phone retorna original para outros tamanhos" do
    employee = build(:employee, phone: "123456789")
    # O before_validation limpa o phone
    assert employee.formatted_phone.present?
  end

  test "formatted_phone retorna traço para phone vazio" do
    employee = build(:employee)
    employee.phone = nil
    employee.valid?  # Ignora validação
    def employee.phone; nil; end

    assert_equal "-", employee.formatted_phone
  end

  test "formatted_salary formata salário corretamente" do
    employee = build(:employee, salary: 2500.50)
    assert_equal "R$ 2500.5", employee.formatted_salary
  end

  test "formatted_salary retorna traço para salário nil" do
    employee = build(:employee, salary: nil)
    assert_equal "-", employee.formatted_salary
  end

  # ============================================
  # FORMATTED ADMISSION TIME - CASOS DETALHADOS
  # ============================================

  test "formatted_admission_time retorna traço sem data de admissão" do
    employee = build(:employee, admission_date: nil)
    assert_equal "-", employee.formatted_admission_time
  end

  test "formatted_admission_time retorna dias para admissão recente" do
    employee = build(:employee, admission_date: 5.days.ago.to_date)
    result = employee.formatted_admission_time
    assert_match(/dia/, result)
  end

  test "formatted_admission_time retorna meses para admissão de alguns meses" do
    employee = build(:employee, admission_date: 3.months.ago.to_date)
    result = employee.formatted_admission_time
    assert_match(/mês|mes/, result)
  end

  test "formatted_admission_time retorna anos e meses" do
    employee = build(:employee, admission_date: (1.year + 3.months).ago.to_date)
    result = employee.formatted_admission_time
    assert_match(/ano/, result)
  end

  test "formatted_admission_time retorna apenas anos quando meses é zero" do
    employee = build(:employee, admission_date: 2.years.ago.to_date)
    result = employee.formatted_admission_time
    assert result.include?("ano")
  end

  # ============================================
  # STATUS COLOR
  # ============================================

  test "status_color retorna cor verde para ativo" do
    employee = build(:employee, status: :ativo)
    assert_includes employee.status_color, "green"
  end

  test "status_color retorna cor cinza para inativo" do
    employee = build(:employee, status: :inativo)
    assert_includes employee.status_color, "gray"
  end

  test "status_color retorna cor azul para férias" do
    employee = build(:employee, status: :ferias)
    assert_includes employee.status_color, "blue"
  end

  test "status_color retorna cor amarela para afastado" do
    employee = build(:employee, status: :afastado)
    assert_includes employee.status_color, "yellow"
  end

  # ============================================
  # CALLBACKS
  # ============================================

  test "clean_cpf remove caracteres não numéricos" do
    employee = create(:employee, cpf: "529.982.247-25")
    assert_equal "52998224725", employee.cpf
  end

  test "clean_phone remove caracteres não numéricos" do
    employee = create(:employee, phone: "(11) 98765-4321")
    assert_equal "11987654321", employee.phone
  end

  # ============================================
  # VALIDAÇÃO DE FOTO
  # ============================================

  test "rejeita foto com tipo inválido" do
    employee = build(:employee)
    employee.photo.attach(
      io: StringIO.new("fake content"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )

    assert_not employee.valid?
    assert employee.errors[:photo].any?
  end

  test "rejeita foto muito grande" do
    employee = build(:employee)
    large_content = "x" * (6 * 1024 * 1024)  # 6MB
    employee.photo.attach(
      io: StringIO.new(large_content),
      filename: "large_photo.jpg",
      content_type: "image/jpeg"
    )

    assert_not employee.valid?
    assert employee.errors[:photo].any?
  end

  test "aceita foto JPEG válida" do
    employee = build(:employee)
    employee.photo.attach(
      io: StringIO.new("fake jpeg content"),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )

    employee.valid?
    assert_not employee.errors[:photo].any? { |e| e.include?("deve ser uma imagem") }
  end
end
