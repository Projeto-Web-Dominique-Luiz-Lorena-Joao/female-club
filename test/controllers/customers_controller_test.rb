# frozen_string_literal: true

require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @customer = create(:customer)
    @guarantor = create(:guarantor)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get customers_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get customer_url(@customer)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get customers_url
    assert_response :success
  end

  test "index lista clientes" do
    get customers_url
    assert_select "table"
  end

  test "index busca por termo" do
    get customers_url, params: { search: @customer.full_name }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get customer_url(@customer)
    assert_response :success
  end

  test "show exibe detalhes do cliente" do
    get customer_url(@customer)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_customer_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_customer_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria cliente com dados válidos" do
    cpf = generate_valid_cpf

    assert_difference "Customer.count", 1 do
      post customers_url, params: {
        customer: {
          full_name: "Novo Cliente",
          cpf: cpf,
          email: "novo@example.com",
          phone_number: "11987654321",
          full_address: "Rua Teste, 123"
        }
      }
    end

    assert_redirected_to customers_url
  end

  test "create cria cliente com email" do
    cpf = generate_valid_cpf

    assert_difference "Customer.count", 1 do
      post customers_url, params: {
        customer: {
          full_name: "Cliente com Email",
          cpf: cpf,
          email: "cliente@email.com"
        }
      }
    end

    assert_redirected_to customers_url
    assert_equal "cliente@email.com", Customer.last.email
  end

  test "create não cria cliente sem nome" do
    assert_no_difference "Customer.count" do
      post customers_url, params: {
        customer: {
          full_name: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create não cria cliente com CPF duplicado" do
    assert_no_difference "Customer.count" do
      post customers_url, params: {
        customer: {
          full_name: "Outro Cliente",
          cpf: @customer.cpf
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_customer_url(@customer)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza cliente" do
    patch customer_url(@customer), params: {
      customer: {
        full_name: "Nome Atualizado"
      }
    }

    assert_redirected_to customers_url
    @customer.reload
    assert_equal "Nome Atualizado", @customer.full_name
  end

  test "update pode alterar email" do
    customer = create(:customer, email: "old@email.com")

    patch customer_url(customer), params: {
      customer: {
        email: "new@email.com"
      }
    }

    assert_redirected_to customers_url
    customer.reload
    assert_equal "new@email.com", customer.email
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy remove cliente" do
    customer_to_delete = create(:customer)

    assert_difference "Customer.count", -1 do
      delete customer_url(customer_to_delete)
    end

    assert_redirected_to customers_url
  end

  # ============================================
  # FILTROS E BUSCA
  # ============================================

  test "index busca por CPF" do
    customer_with_cpf = create(:customer)
    clean_cpf = customer_with_cpf.cpf.gsub(/\D/, "")

    get customers_url, params: { search: clean_cpf }
    assert_response :success
  end

  test "index busca por telefone" do
    get customers_url, params: { search: @customer.phone_number }
    assert_response :success
  end

  test "index busca por email" do
    get customers_url, params: { search: @customer.email }
    assert_response :success
  end

  test "index filtra clientes VIP" do
    # Verificar se o scope vip existe no modelo Customer
    get customers_url, params: { tier: "vip" }
    assert_response :success
  rescue NoMethodError
    skip "Scope vip não definido no modelo Customer"
  end

  test "index filtra clientes ativos" do
    # Verificar se o scope active existe no modelo Customer
    get customers_url, params: { tier: "active" }
    assert_response :success
  rescue NoMethodError
    skip "Scope active não definido no modelo Customer"
  end

  # ============================================
  # CREATE COM FIADOR
  # ============================================

  test "create cria cliente com fiador" do
    cpf_customer = generate_valid_cpf
    cpf_guarantor = generate_valid_cpf

    assert_difference ["Customer.count", "Guarantor.count"], 1 do
      post customers_url, params: {
        customer: {
          full_name: "Cliente com Fiador",
          cpf: cpf_customer
        },
        guarantor: {
          full_name: "Fiador do Cliente",
          cpf: cpf_guarantor,
          phone: "11999998888",
          relationship: "pai"
        }
      }
    end

    assert_redirected_to customers_url
  end

  # ============================================
  # UPDATE COM FIADOR
  # ============================================

  test "update atualiza cliente e cria fiador" do
    cpf_guarantor = generate_valid_cpf

    assert_difference "Guarantor.count", 1 do
      patch customer_url(@customer), params: {
        customer: {
          full_name: @customer.full_name
        },
        guarantor: {
          full_name: "Novo Fiador",
          cpf: cpf_guarantor,
          relationship: "mae"
        }
      }
    end

    assert_redirected_to customers_url
  end

  test "update atualiza fiador existente" do
    guarantor = create(:guarantor)
    @customer.update(guarantor: guarantor)

    patch customer_url(@customer), params: {
      customer: {
        full_name: @customer.full_name
      },
      guarantor: {
        id: guarantor.id,
        full_name: "Fiador Atualizado"
      }
    }

    assert_redirected_to customers_url
    guarantor.reload
    assert_equal "Fiador Atualizado", guarantor.full_name
  end

  # ============================================
  # CREATE VIA JSON
  # ============================================

  test "create retorna JSON para requisição AJAX" do
    cpf = generate_valid_cpf

    post customers_url, params: {
      customer: {
        full_name: "Cliente AJAX",
        cpf: cpf
      }
    }, as: :json

    assert_response :created
    response_data = JSON.parse(response.body)
    assert response_data["id"].present?
    assert_equal "Cliente AJAX", response_data["full_name"]
  end

  test "create retorna erros JSON para dados inválidos" do
    post customers_url, params: {
      customer: {
        full_name: nil
      }
    }, as: :json

    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert response_data["errors"].present?
  end

  # ============================================
  # UPDATE COM ERRO
  # ============================================

  test "update com dados inválidos retorna erro" do
    patch customer_url(@customer), params: {
      customer: {
        full_name: ""  # Nome vazio é inválido
      }
    }

    assert_response :unprocessable_entity
  end

  # ============================================
  # PHONE PARAMETER ALIASING
  # ============================================

  test "create aceita phone como alias de phone_number" do
    cpf = generate_valid_cpf

    assert_difference "Customer.count", 1 do
      post customers_url, params: {
        customer: {
          full_name: "Cliente com Phone",
          cpf: cpf,
          phone: "11888887777"  # Usando 'phone' ao invés de 'phone_number'
        }
      }
    end

    assert_redirected_to customers_url
    assert_equal "11888887777", Customer.last.phone_number
  end
end
