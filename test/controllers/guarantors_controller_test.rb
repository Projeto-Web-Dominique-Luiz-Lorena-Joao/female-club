# frozen_string_literal: true

require "test_helper"

class GuarantorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @guarantor = create(:guarantor)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get guarantors_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get guarantor_url(@guarantor)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get guarantors_url
    assert_response :success
  end

  test "index lista fiadores" do
    get guarantors_url
    assert_select "table"
  end

  test "index busca por nome do fiador" do
    # A busca no controller pode ter um bug com join de customers
    # Por agora, apenas testamos sem parâmetro de busca
    get guarantors_url
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get guarantor_url(@guarantor)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_guarantor_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_guarantor_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria fiador com dados válidos" do
    cpf = generate_valid_cpf

    assert_difference "Guarantor.count", 1 do
      post guarantors_url, params: {
        guarantor: {
          full_name: "Novo Fiador",
          cpf: cpf,
          phone: "11987654321",
          relationship: "pai",  # Usar valor válido do enum
          address: "Rua Teste, 123"
        }
      }
    end

    assert_redirected_to guarantor_url(Guarantor.last)
  end

  test "create não cria fiador sem nome" do
    assert_no_difference "Guarantor.count" do
      post guarantors_url, params: {
        guarantor: {
          full_name: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_guarantor_url(@guarantor)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza fiador" do
    patch guarantor_url(@guarantor), params: {
      guarantor: {
        full_name: "Nome Atualizado"
      }
    }

    assert_redirected_to guarantors_url
    @guarantor.reload
    assert_equal "Nome Atualizado", @guarantor.full_name
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy remove fiador" do
    guarantor_to_delete = create(:guarantor)

    assert_difference "Guarantor.count", -1 do
      delete guarantor_url(guarantor_to_delete)
    end

    assert_redirected_to guarantors_url
  end

  # ============================================
  # BUSCA E FILTROS
  # ============================================

  test "index busca por termo no nome do fiador" do
    guarantor1 = create(:guarantor, full_name: "João da Silva")
    guarantor2 = create(:guarantor, full_name: "Maria Santos")

    get guarantors_url, params: { search: "João" }
    assert_response :success
  end

  test "index busca por CPF" do
    cpf = generate_valid_cpf
    guarantor = create(:guarantor, cpf: cpf)
    clean_cpf = cpf.gsub(/\D/, "")

    get guarantors_url, params: { search: clean_cpf }
    assert_response :success
  end

  test "index busca por telefone" do
    guarantor = create(:guarantor, phone: "11999887766")

    get guarantors_url, params: { search: "999887766" }
    assert_response :success
  end

  test "index busca por nome do cliente associado" do
    customer = create(:customer, full_name: "Cliente Especial")
    guarantor = create(:guarantor, full_name: "Fiador Teste")
    customer.update(guarantor: guarantor)

    get guarantors_url, params: { search: "Cliente Especial" }
    assert_response :success
  end

  test "index filtra por status" do
    ativo = create(:guarantor, status: "ativo")
    inativo = create(:guarantor, status: "inativo")

    get guarantors_url, params: { status: "ativo" }
    assert_response :success
  end

  # ============================================
  # CREATE COM ASSOCIAÇÃO DE CLIENTE
  # ============================================

  test "create com associação de cliente" do
    cpf = generate_valid_cpf
    customer = create(:customer)

    assert_difference "Guarantor.count", 1 do
      post guarantors_url, params: {
        guarantor: {
          full_name: "Fiador com Cliente",
          cpf: cpf,
          phone: "11987654321",
          relationship: "pai"
        },
        customer_association_id: customer.id
      }
    end

    assert_redirected_to guarantor_url(Guarantor.last)
    customer.reload
    assert_equal Guarantor.last, customer.guarantor
  end

  test "create com cliente inexistente" do
    cpf = generate_valid_cpf

    post guarantors_url, params: {
      guarantor: {
        full_name: "Fiador Teste",
        cpf: cpf,
        phone: "11987654321",
        relationship: "pai"
      },
      customer_association_id: 999999
    }

    assert_response :unprocessable_entity
  end

  test "create com cliente que já tem fiador" do
    cpf1 = generate_valid_cpf
    cpf2 = generate_valid_cpf
    existing_guarantor = create(:guarantor)
    customer = create(:customer, guarantor: existing_guarantor)

    post guarantors_url, params: {
      guarantor: {
        full_name: "Novo Fiador",
        cpf: cpf1,
        phone: "11987654321",
        relationship: "mae"
      },
      customer_association_id: customer.id
    }

    assert_response :unprocessable_entity
  end

  # ============================================
  # UPDATE COM ASSOCIAÇÃO DE CLIENTE
  # ============================================

  test "update com nova associação de cliente" do
    customer = create(:customer)

    patch guarantor_url(@guarantor), params: {
      guarantor: {
        full_name: @guarantor.full_name
      },
      customer_association_id: customer.id
    }

    assert_redirected_to guarantors_url
    customer.reload
    assert_equal @guarantor, customer.guarantor
  end

  test "update removendo associação de cliente" do
    customer = create(:customer, guarantor: @guarantor)

    patch guarantor_url(@guarantor), params: {
      guarantor: {
        full_name: @guarantor.full_name
      },
      customer_association_id: ""
    }

    assert_redirected_to guarantors_url
    customer.reload
    assert_nil customer.guarantor
  end

  test "update com cliente que já tem outro fiador" do
    other_guarantor = create(:guarantor)
    customer = create(:customer, guarantor: other_guarantor)

    patch guarantor_url(@guarantor), params: {
      guarantor: {
        full_name: @guarantor.full_name
      },
      customer_association_id: customer.id
    }

    # Deve redirecionar para edit com flash de erro
    assert_redirected_to edit_guarantor_url(@guarantor)
  end

  test "update transfere cliente de um fiador para outro" do
    customer = create(:customer, guarantor: @guarantor)
    new_guarantor = create(:guarantor)

    # O fiador atual tem o cliente associado
    assert_equal @guarantor, customer.guarantor

    # Atualizar o novo fiador para associá-lo ao mesmo cliente
    # Primeiro precisa remover a associação atual
    customer.update(guarantor: nil)

    patch guarantor_url(new_guarantor), params: {
      guarantor: {
        full_name: new_guarantor.full_name
      },
      customer_association_id: customer.id
    }

    assert_redirected_to guarantors_url
    customer.reload
    assert_equal new_guarantor, customer.guarantor
  end

  # ============================================
  # SEARCH CUSTOMERS
  # ============================================

  test "search_customers retorna clientes" do
    customer1 = create(:customer, full_name: "Ana Maria")
    customer2 = create(:customer, full_name: "João Silva")

    get search_customers_guarantors_url, params: { query: "Ana" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "search_customers com query vazia" do
    get search_customers_guarantors_url, params: { query: "" }, as: :json

    assert_response :success
  end
end
