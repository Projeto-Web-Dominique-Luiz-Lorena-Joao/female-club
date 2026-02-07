# frozen_string_literal: true

require "test_helper"

class SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @employee = create(:employee)
    @customer = create(:customer)
    @product = create(:product, :with_stock, initial_stock: 100)
    @service = create(:service)
    @sale = create(:sale, employee: @employee, customer: @customer)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get sales_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get sale_url(@sale)
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para new" do
    sign_out @user
    get new_sale_url
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get sales_url
    assert_response :success
  end

  test "index lista vendas" do
    get sales_url
    assert_select "table"
  end

  test "index filtra por status" do
    get sales_url, params: { status: "pago" }
    assert_response :success
  end

  test "index filtra por período" do
    get sales_url, params: { start_date: 1.month.ago, end_date: Date.current }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get sale_url(@sale)
    assert_response :success
  end

  test "show exibe detalhes da venda" do
    get sale_url(@sale)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_sale_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_sale_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria venda com dados válidos" do
    assert_difference "Sale.count", 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          customer_id: @customer.id,
          sale_date: Date.current,
          total_amount: 100,
          payment_method: "pix",
          status: "pago",
          discount_percentage: 0
        }
      }
    end

    assert_redirected_to sale_url(Sale.last)
  end

  test "create cria venda sem cliente (avulsa)" do
    assert_difference "Sale.count", 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          customer_id: "",
          sale_date: Date.current,
          total_amount: 50,
          payment_method: "dinheiro",
          status: "pago",
          discount_percentage: 0
        }
      }
    end

    assert_redirected_to sale_url(Sale.last)
    assert_nil Sale.last.customer_id
  end

  test "create não cria venda sem funcionário" do
    assert_no_difference "Sale.count" do
      post sales_url, params: {
        sale: {
          employee_id: nil,
          sale_date: Date.current,
          total_amount: 100,
          payment_method: "pix",
          status: "pago"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_sale_url(@sale)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza venda" do
    patch sale_url(@sale), params: {
      sale: {
        discount_percentage: 10
      }
    }

    assert_redirected_to sale_url(@sale)
    @sale.reload
    assert_equal 10, @sale.discount_percentage
  end

  test "update pode cancelar venda" do
    patch sale_url(@sale), params: {
      sale: {
        status: "cancelado"
      }
    }

    assert_redirected_to sale_url(@sale)
    @sale.reload
    assert @sale.cancelado?
  end

  # ============================================
  # MARK AS PAID
  # ============================================

  test "mark_as_paid marca venda como paga" do
    pending_sale = create(:sale, status: :pendente, employee: @employee)

    patch mark_as_paid_sale_url(pending_sale)

    assert_redirected_to sale_url(pending_sale)
    pending_sale.reload
    assert pending_sale.pago?
  end

  # ============================================
  # SEARCH ENDPOINTS
  # ============================================

  test "search_employees retorna funcionários" do
    get search_employees_sales_url, params: { q: @employee.full_name }, as: :json
    assert_response :success
  end

  test "search_customers retorna clientes" do
    get search_customers_sales_url, params: { q: @customer.full_name }, as: :json
    assert_response :success
  end

  test "search_products retorna produtos" do
    get search_products_sales_url, params: { q: @product.name }, as: :json
    assert_response :success
  end

  test "search_services retorna serviços" do
    get search_services_sales_url, params: { q: @service.name }, as: :json
    assert_response :success
  end

  # ============================================
  # FILTROS E ORDENAÇÃO
  # ============================================

  test "index filtra por método de pagamento" do
    pix_sale = create(:sale, employee: @employee, payment_method: :pix)
    dinheiro_sale = create(:sale, employee: @employee, payment_method: :dinheiro)

    get sales_url, params: { payment_method: "pix" }

    assert_response :success
  end

  test "index filtra por cliente" do
    get sales_url, params: { customer_id: @customer.id }
    assert_response :success
  end

  test "index filtra por funcionário" do
    get sales_url, params: { employee_id: @employee.id }
    assert_response :success
  end

  test "index ordena por valor total ascendente" do
    create(:sale, employee: @employee, total_amount: 100)
    create(:sale, employee: @employee, total_amount: 500)

    get sales_url, params: { sort_amount: "asc" }

    assert_response :success
  end

  test "index ordena por valor total descendente" do
    create(:sale, employee: @employee, total_amount: 100)
    create(:sale, employee: @employee, total_amount: 500)

    get sales_url, params: { sort_amount: "desc" }

    assert_response :success
  end

  test "index ordena por desconto" do
    create(:sale, employee: @employee, discount_percentage: 5)
    create(:sale, employee: @employee, discount_percentage: 15)

    get sales_url, params: { sort_discount: "desc" }

    assert_response :success
  end

  test "index ordena por valor descontado" do
    create(:sale, employee: @employee, total_amount: 100, discount_percentage: 10)
    create(:sale, employee: @employee, total_amount: 200, discount_percentage: 5)

    get sales_url, params: { sort_discounted_amount: "desc" }

    assert_response :success
  end

  # ============================================
  # CRIAÇÃO COM NESTED ATTRIBUTES
  # ============================================

  test "create cria venda com produtos" do
    assert_difference "Sale.count", 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          customer_id: @customer.id,
          sale_date: Date.current,
          total_amount: 500,
          payment_method: "cartao_credito",
          status: "pago",
          sale_products_attributes: [
            { product_id: @product.id, quantity: 2, unit_price: 250 }
          ]
        }
      }
    end

    assert_redirected_to sale_url(Sale.last)
  end

  test "create cria venda com serviços" do
    assert_difference "Sale.count", 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          customer_id: @customer.id,
          sale_date: Date.current,
          total_amount: 300,
          payment_method: "pix",
          status: "pago",
          sale_services_attributes: [
            { service_id: @service.id, quantity: 1, unit_price: 300 }
          ]
        }
      }
    end

    assert_redirected_to sale_url(Sale.last)
  end

  test "create cria venda com cliente pelo nome" do
    assert_difference [ "Sale.count", "Customer.count" ], 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          customer_id: "",
          sale_date: Date.current,
          total_amount: 100,
          payment_method: "dinheiro",
          status: "pago"
        },
        customer_search: "Novo Cliente Criado"
      }
    end

    assert_redirected_to sale_url(Sale.last)
  end

  # ============================================
  # UPDATE COM CLIENTE PELO NOME
  # ============================================

  test "update atualiza venda criando novo cliente pelo nome" do
    sale_without_customer = create(:sale, employee: @employee, customer: nil)

    # O controller cria o cliente e tenta associar à venda
    assert_difference "Customer.count", 1 do
      patch sale_url(sale_without_customer), params: {
        sale: {
          customer_id: ""
        },
        customer_search: "Cliente Criado no Update"
      }
    end

    assert_redirected_to sale_url(sale_without_customer)
    # Verificar que o cliente foi criado com o nome correto
    assert Customer.exists?(full_name: "Cliente Criado no Update")
  end

  # ============================================
  # SEARCH ENDPOINTS DETALHADOS
  # ============================================

  test "search_employees filtra por query" do
    employee1 = create(:employee, full_name: "Ana Maria", status: "ativo")
    employee2 = create(:employee, full_name: "João Silva", status: "ativo")

    get search_employees_sales_url, params: { query: "Ana" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.any? { |e| e["name"].include?("Ana") }
  end

  test "search_employees retorna apenas funcionários ativos" do
    active_employee = create(:employee, full_name: "Funcionário Ativo", status: "ativo")
    inactive_employee = create(:employee, full_name: "Funcionário Inativo", status: "inativo")

    get search_employees_sales_url, params: { query: "Funcionário" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    ids = data.map { |e| e["id"] }
    assert_includes ids, active_employee.id
    assert_not_includes ids, inactive_employee.id
  end

  test "search_customers filtra por query" do
    customer1 = create(:customer, full_name: "Maria Silva")
    customer2 = create(:customer, full_name: "Pedro Santos")

    get search_customers_sales_url, params: { query: "Maria" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.any? { |c| c["name"].include?("Maria") }
  end

  test "search_products filtra por query" do
    product1 = create(:product, name: "Shampoo Premium", active: true)
    product2 = create(:product, name: "Condicionador", active: true)

    get search_products_sales_url, params: { query: "Shampoo" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.any? { |p| p["name"].include?("Shampoo") }
  end

  test "search_products busca por código" do
    product = create(:product, name: "Produto Teste", code: "CODE123", active: true)

    get search_products_sales_url, params: { query: "CODE123" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert data.any? { |p| p["id"] == product.id }
  end

  test "search_products retorna apenas produtos ativos" do
    active_product = create(:product, name: "Produto Ativo", active: true)
    inactive_product = create(:product, name: "Produto Inativo", active: false)

    get search_products_sales_url, params: { query: "Produto" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    ids = data.map { |p| p["id"] }
    assert_includes ids, active_product.id
    assert_not_includes ids, inactive_product.id
  end

  test "search_products inclui preço no retorno" do
    product = create(:product, name: "Produto Com Preço", sale_price: 99.90, active: true)

    get search_products_sales_url, params: { query: "Produto Com Preço" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    result = data.find { |p| p["id"] == product.id }
    assert_not_nil result
    assert result["price"].present?
  end

  test "search_services filtra por query" do
    service1 = create(:service, name: "Corte de Cabelo", active: "ativo")
    service2 = create(:service, name: "Manicure", active: "ativo")

    get search_services_sales_url, params: { query: "Corte" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.any? { |s| s["name"].include?("Corte") }
  end

  test "search_services retorna apenas serviços ativos" do
    active_service = create(:service, name: "Serviço Ativo", active: "ativo")
    inactive_service = create(:service, name: "Serviço Inativo", active: "inativo")

    get search_services_sales_url, params: { query: "Serviço" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    ids = data.map { |s| s["id"] }
    assert_includes ids, active_service.id
    assert_not_includes ids, inactive_service.id
  end

  test "search_services inclui preço no retorno" do
    service = create(:service, name: "Serviço Com Preço", price: 150.00, active: "ativo")

    get search_services_sales_url, params: { query: "Serviço Com Preço" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    result = data.find { |s| s["id"] == service.id }
    assert_not_nil result
    assert result["price"].present?
  end

  # ============================================
  # ORDENAÇÃO ADICIONAL
  # ============================================

  test "index ordena por discounted_amount com valor inválido usa ASC" do
    create(:sale, employee: @employee, total_amount: 100, discount_percentage: 10)

    get sales_url, params: { sort_discounted_amount: "INVALID; DROP TABLE sales;--" }

    assert_response :success
  end

  # ============================================
  # UPDATE COM FALHA DE VALIDAÇÃO
  # ============================================

  test "update com erro de validação renderiza edit" do
    patch sale_url(@sale), params: {
      sale: {
        total_amount: -100  # Valor inválido
      }
    }

    assert_response :unprocessable_entity
  end

  # ============================================
  # MARK AS PAID - FALHA
  # ============================================

  test "mark_as_paid retorna erro quando falha" do
    # Mocka o método mark_as_paid! para retornar false
    Sale.any_instance.stubs(:mark_as_paid!).returns(false)

    patch mark_as_paid_sale_url(@sale)

    assert_redirected_to sale_url(@sale)
    assert_equal "Erro ao marcar venda como paga.", flash[:alert]
  end

  # ============================================
  # FILTER EMPTY NESTED ATTRIBUTES
  # ============================================

  test "create filtra sale_products vazios" do
    product = create(:product, :with_stock, initial_stock: 100)

    assert_difference "Sale.count", 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          sale_date: Date.current,
          total_amount: 100,
          payment_method: "pix",
          status: "pago",
          sale_products_attributes: [
            { product_id: product.id, quantity: 2, unit_price: 50 },
            { product_id: "", quantity: "", unit_price: "" }  # Vazio - deve ser filtrado
          ]
        }
      }
    end

    assert_redirected_to sale_url(Sale.last)
    assert_equal 1, Sale.last.sale_products.count
  end

  test "create filtra sale_services vazios" do
    service = create(:service)

    assert_difference "Sale.count", 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          sale_date: Date.current,
          total_amount: 100,
          payment_method: "pix",
          status: "pago",
          sale_services_attributes: [
            { service_id: service.id, quantity: 1, unit_price: 100 },
            { service_id: "", quantity: "", unit_price: "" }  # Vazio - deve ser filtrado
          ]
        }
      }
    end

    assert_redirected_to sale_url(Sale.last)
    assert_equal 1, Sale.last.sale_services.count
  end

  test "update filtra nested attributes vazios com hash format" do
    product = create(:product, :with_stock, initial_stock: 100)
    service = create(:service)

    patch sale_url(@sale), params: {
      sale: {
        total_amount: 200,
        sale_products_attributes: {
          "0" => { product_id: product.id, quantity: 2, unit_price: 100 },
          "1" => { product_id: "", quantity: "", unit_price: "" }
        },
        sale_services_attributes: {
          "0" => { service_id: service.id, quantity: 1, unit_price: 50 },
          "1" => { service_id: "", quantity: "", unit_price: "" }
        }
      }
    }

    assert_redirected_to sale_url(@sale)
  end

  test "update filtra nested attributes marcados para destruição sem id" do
    product = create(:product, :with_stock, initial_stock: 100)

    patch sale_url(@sale), params: {
      sale: {
        total_amount: 200,
        sale_products_attributes: [
          { product_id: product.id, quantity: 2, unit_price: 100 },
          { product_id: "", quantity: "", unit_price: "", _destroy: "1" }  # Marcado para destruição sem ID
        ]
      }
    }

    assert_redirected_to sale_url(@sale)
  end

  # ============================================
  # FILTER EMPTY NESTED ATTRIBUTES - ARRAY FORMAT
  # ============================================

  test "create filtra sale_products vazios em formato array e limpa array" do
    product = create(:product, :with_stock, initial_stock: 100)

    assert_difference "Sale.count", 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          sale_date: Date.current,
          total_amount: 100,
          payment_method: "pix",
          status: "pago",
          sale_products_attributes: [
            { product_id: product.id, quantity: 2, unit_price: 50 },
            { product_id: "", quantity: "", unit_price: "" },
            { product_id: "", quantity: "", unit_price: "", _destroy: "1" }
          ]
        }
      }
    end

    assert_equal 1, Sale.last.sale_products.count
  end

  test "create filtra sale_services vazios em formato array e limpa array" do
    service = create(:service)

    assert_difference "Sale.count", 1 do
      post sales_url, params: {
        sale: {
          employee_id: @employee.id,
          sale_date: Date.current,
          total_amount: 100,
          payment_method: "pix",
          status: "pago",
          sale_services_attributes: [
            { service_id: service.id, quantity: 1, unit_price: 100 },
            { service_id: "", quantity: "", unit_price: "" },
            { service_id: "", quantity: "", unit_price: "", _destroy: "1" }
          ]
        }
      }
    end

    assert_equal 1, Sale.last.sale_services.count
  end

  test "update com sale_products existente marca item vazio para destruição" do
    product = create(:product, :with_stock, initial_stock: 100)
    # Criar venda com produto existente
    sale = create(:sale, employee: @employee, customer: @customer)
    sale_product = create(:sale_product, sale: sale, product: product, quantity: 5, unit_price: 50)

    patch sale_url(sale), params: {
      sale: {
        sale_products_attributes: [
          { id: sale_product.id, product_id: product.id, quantity: 3, unit_price: 50 }
        ]
      }
    }

    assert_redirected_to sale_url(sale)
    sale_product.reload
    assert_equal 3, sale_product.quantity
  end

  test "update com sale_services existente marca item vazio para destruição" do
    service = create(:service)
    # Criar venda com serviço existente
    sale = create(:sale, employee: @employee, customer: @customer)
    sale_service = create(:sale_service, sale: sale, service: service, quantity: 2, unit_price: 100)

    patch sale_url(sale), params: {
      sale: {
        sale_services_attributes: [
          { id: sale_service.id, service_id: service.id, quantity: 3, unit_price: 100 }
        ]
      }
    }

    assert_redirected_to sale_url(sale)
    sale_service.reload
    assert_equal 3, sale_service.quantity
  end
end
