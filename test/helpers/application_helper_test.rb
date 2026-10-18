# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # ============================================
  # ACTIVE CLASS
  # ============================================

  test "active_class retorna classe ativa quando na página atual" do
    # Simula estar na página atual
    def current_page?(path)
      path == "/test"
    end

    result = active_class("/test")
    assert_equal "bg-white text-black", result
  end

  test "active_class retorna classe inativa quando não na página atual" do
    # Simula não estar na página atual
    def current_page?(path)
      false
    end

    result = active_class("/other")
    assert_equal "text-gray-300 hover:bg-white/10 hover:text-white", result
  end

  # ============================================
  # ACTIVE SUBMENU
  # ============================================

  test "active_submenu? retorna true quando uma das paths é atual" do
    def current_page?(path)
      path == "/path2"
    end

    result = active_submenu?("/path1", "/path2", "/path3")
    assert result
  end

  test "active_submenu? retorna false quando nenhuma path é atual" do
    def current_page?(path)
      false
    end

    result = active_submenu?("/path1", "/path2", "/path3")
    assert_not result
  end

  # ============================================
  # SAFE JSON
  # ============================================

  test "safe_json escapa caracteres perigosos" do
    data = { name: "<script>alert('xss')</script>" }
    result = safe_json(data)

    # Deve escapar caracteres HTML/JS
    assert_not_includes result, "<script>"
  end

  test "safe_json serializa hash corretamente" do
    data = { id: 1, name: "Test" }
    result = safe_json(data)

    # O resultado deve ser JSON válido (com escaping)
    assert result.present?
  end

  test "safe_json serializa array corretamente" do
    data = [ 1, 2, 3 ]
    result = safe_json(data)

    assert result.present?
  end

  # ============================================
  # SANITIZE FOR DISPLAY
  # ============================================

  test "sanitize_for_display escapa HTML" do
    text = "<script>alert('xss')</script>"
    result = sanitize_for_display(text)

    assert_not_includes result, "<script>"
    assert_includes result, "&lt;script&gt;"
  end

  test "sanitize_for_display retorna string vazia para nil" do
    result = sanitize_for_display(nil)
    assert_equal "", result
  end

  test "sanitize_for_display retorna string vazia para string vazia" do
    result = sanitize_for_display("")
    assert_equal "", result
  end

  test "sanitize_for_display converte números para string" do
    result = sanitize_for_display(123)
    assert_equal "123", result
  end

  test "sanitize_for_display preserva texto seguro" do
    text = "Texto normal sem HTML"
    result = sanitize_for_display(text)
    assert_equal text, result
  end

  test "sanitize_for_display escapa ampersand" do
    text = "Teste & Exemplo"
    result = sanitize_for_display(text)
    assert_includes result, "&amp;"
  end

  test "sanitize_for_display escapa aspas" do
    text = 'Texto com "aspas"'
    result = sanitize_for_display(text)
    assert_includes result, "&quot;"
  end
end
