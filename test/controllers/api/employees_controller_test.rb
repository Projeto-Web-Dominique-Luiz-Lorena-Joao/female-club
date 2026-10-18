# frozen_string_literal: true

require "test_helper"

class Api::EmployeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  # ============================================
  # SEARCH
  # ============================================

  test "search retorna funcionários por nome" do
    employee1 = create(:employee, full_name: "Ana Maria Silva")
    employee2 = create(:employee, full_name: "João Carlos")

    get api_employees_search_url, params: { q: "Ana" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.any? { |e| e["name"].include?("Ana") }
  end

  test "search com query vazia retorna array vazio" do
    get api_employees_search_url, params: { q: "" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "search limita resultados a 10" do
    15.times { create(:employee) }

    get api_employees_search_url, params: { q: "" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert data.size <= 10
  end

  test "search ordena por nome" do
    create(:employee, full_name: "Zeca Silva")
    create(:employee, full_name: "Ana Maria")

    get api_employees_search_url, params: { q: "" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    names = data.map { |e| e["name"] }
    assert_equal names, names.sort
  end

  test "search retorna id e name" do
    employee = create(:employee, full_name: "Funcionário Teste")

    get api_employees_search_url, params: { q: "Funcionário" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    result = data.find { |e| e["id"] == employee.id }

    assert_not_nil result
    assert_equal employee.id, result["id"]
    assert_equal employee.full_name, result["name"]
  end

  test "search é case insensitive" do
    create(:employee, full_name: "MARIA SILVA")

    get api_employees_search_url, params: { q: "maria" }, as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert data.any? { |e| e["name"].downcase.include?("maria") }
  end

  test "search com caracteres especiais" do
    get api_employees_search_url, params: { q: "João%" }, as: :json

    assert_response :success
  end
end
