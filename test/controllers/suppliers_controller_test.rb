# frozen_string_literal: true

require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user

    @supplier = create(:supplier)
  end

  # ============================================
  # AUTENTICAÇÃO
  # ============================================

  test "requer autenticação para index" do
    sign_out @user
    get suppliers_url
    assert_redirected_to new_user_session_path
  end

  test "requer autenticação para show" do
    sign_out @user
    get supplier_url(@supplier)
    assert_redirected_to new_user_session_path
  end

  # ============================================
  # INDEX
  # ============================================

  test "index retorna sucesso" do
    get suppliers_url
    assert_response :success
  end

  test "index lista fornecedores" do
    get suppliers_url
    assert_select "table"
  end

  test "index busca por termo" do
    get suppliers_url, params: { search: @supplier.legal_name }
    assert_response :success
  end

  # ============================================
  # SHOW
  # ============================================

  test "show retorna sucesso" do
    get supplier_url(@supplier)
    assert_response :success
  end

  # ============================================
  # NEW
  # ============================================

  test "new retorna sucesso" do
    get new_supplier_url
    assert_response :success
  end

  test "new exibe formulário" do
    get new_supplier_url
    assert_select "form"
  end

  # ============================================
  # CREATE
  # ============================================

  test "create cria fornecedor com dados válidos" do
    assert_difference "Supplier.count", 1 do
      post suppliers_url, params: {
        supplier: {
          legal_name: "Novo Fornecedor LTDA",
          trade_name: "Novo Fornecedor",
          status: "ativo",
          phone_number: "11987654321"
        }
      }
    end

    assert_redirected_to suppliers_url
  end

  test "create não cria fornecedor sem razão social" do
    assert_no_difference "Supplier.count" do
      post suppliers_url, params: {
        supplier: {
          legal_name: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ============================================
  # EDIT
  # ============================================

  test "edit retorna sucesso" do
    get edit_supplier_url(@supplier)
    assert_response :success
  end

  # ============================================
  # UPDATE
  # ============================================

  test "update atualiza fornecedor" do
    patch supplier_url(@supplier), params: {
      supplier: {
        legal_name: "Fornecedor Atualizado LTDA"
      }
    }

    assert_redirected_to suppliers_url
    @supplier.reload
    assert_equal "Fornecedor Atualizado LTDA", @supplier.legal_name
  end

  # ============================================
  # DESTROY
  # ============================================

  test "destroy inativa fornecedor" do
    supplier_to_inactivate = create(:supplier, status: "ativo")

    delete supplier_url(supplier_to_inactivate)

    assert_redirected_to suppliers_url
    supplier_to_inactivate.reload
    # Nota: O controller faz soft delete (inativa) ao invés de excluir
    assert_not supplier_to_inactivate.active?
  end

  # ============================================
  # FILTROS
  # ============================================

  test "index filtra por categoria" do
    supplier_cat = create(:supplier, product_category: "cosmeticos")
    supplier_other = create(:supplier, product_category: "equipamentos")

    get suppliers_url, params: { category: "cosmeticos" }
    assert_response :success
  end

  test "index filtra por status ativo" do
    active_supplier = create(:supplier, status: "ativo", active: true)
    inactive_supplier = create(:supplier, status: "inativo", active: false)

    get suppliers_url, params: { status: "ativo" }
    assert_response :success
  end

  test "index filtra por status inativo" do
    active_supplier = create(:supplier, status: "ativo", active: true)
    inactive_supplier = create(:supplier, status: "inativo", active: false)

    get suppliers_url, params: { status: "inativo" }
    assert_response :success
  end

  test "index busca por número de telefone" do
    supplier = create(:supplier, phone_number: "11999887766")

    get suppliers_url, params: { search: "999887766" }
    assert_response :success
  end

  test "index busca por telefone com formatação" do
    supplier = create(:supplier, phone_number: "11888776655")

    get suppliers_url, params: { search: "(11) 88877-6655" }
    assert_response :success
  end

  # ============================================
  # REATIVAÇÃO
  # ============================================

  test "reactivate reativa fornecedor inativo" do
    inactive_supplier = create(:supplier, active: false)

    patch reactivate_supplier_url(inactive_supplier)

    assert_redirected_to supplier_path(inactive_supplier)
    inactive_supplier.reload
    assert inactive_supplier.active?
  end

  test "reactivate retorna erro se falhar" do
    inactive_supplier = create(:supplier, active: false)

    # Simular falha na atualização
    Supplier.any_instance.stubs(:update).returns(false)

    patch reactivate_supplier_url(inactive_supplier)

    assert_redirected_to supplier_path(inactive_supplier)
    assert_equal "Não foi possível reativar o fornecedor.", flash[:alert]
  end

  # ============================================
  # ERRO NA ATUALIZAÇÃO
  # ============================================

  test "update com dados inválidos retorna erro" do
    patch supplier_url(@supplier), params: {
      supplier: {
        legal_name: ""  # Nome vazio é inválido
      }
    }

    assert_response :unprocessable_entity
  end
end
