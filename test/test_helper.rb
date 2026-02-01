# frozen_string_literal: true

# IMPORTANTE: SimpleCov DEVE ser carregado e iniciado ANTES de qualquer outro require
require "simplecov"

SimpleCov.start "rails" do
  # Forçar um único nome de comando para evitar fragmentação
  command_name "Tests"

  # Merge timeout para combinar resultados de diferentes execuções
  merge_timeout 3600

  # Filtros para excluir arquivos não relevantes
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_filter "/db/"
  add_filter "/bin/"
  add_filter "/spec/"

  # Rastrear arquivos da aplicação
  track_files "#{SimpleCov.root}/app/**/*.rb"

  # Grupos para organizar o relatório
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Helpers", "app/helpers"
  add_group "Mailers", "app/mailers"
  add_group "Jobs", "app/jobs"
  add_group "Channels", "app/channels"

  # Habilitar cobertura de branch
  enable_coverage :branch
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    # Desabilitar paralelização para evitar problemas com Devise
    # parallelize(workers: :number_of_processors)

    # Usar factories em vez de fixtures para maior flexibilidade
    # fixtures :all

    # Setup executado antes de cada teste
    setup do
      # Limpar cache entre testes
      Rails.cache.clear
    end

    # ============================================
    # HELPERS PARA TESTES
    # ============================================

    # Gera um CPF válido para testes
    def generate_valid_cpf
      cpf = Array.new(9) { rand(0..9) }

      # Primeiro dígito verificador
      sum = cpf.each_with_index.sum { |digit, index| digit * (10 - index) }
      remainder = sum % 11
      cpf << (remainder < 2 ? 0 : 11 - remainder)

      # Segundo dígito verificador
      sum = cpf.each_with_index.sum { |digit, index| digit * (11 - index) }
      remainder = sum % 11
      cpf << (remainder < 2 ? 0 : 11 - remainder)

      cpf.join
    end

    # Gera um email único
    def generate_unique_email(prefix = "test")
      "#{prefix}_#{SecureRandom.hex(8)}@example.com"
    end

    # Gera um telefone válido brasileiro
    def generate_valid_phone
      "11#{rand(900000000..999999999)}"
    end

    # Helper para verificar se um registro é válido com mensagem detalhada
    def assert_valid(record, message = nil)
      assert record.valid?, message || "Expected #{record.class.name} to be valid, but got errors: #{record.errors.full_messages.join(', ')}"
    end

    # Helper para verificar se um registro é inválido
    def assert_invalid(record, attribute = nil, message = nil)
      assert_not record.valid?, message || "Expected #{record.class.name} to be invalid"
      if attribute
        assert record.errors[attribute].any?, "Expected error on #{attribute}, but got: #{record.errors.full_messages.join(', ')}"
      end
    end

    # Helper para criar um agendamento sem conflitos
    def create_appointment_at(employee:, date:, hour:, minute: 0, duration: 60, **attrs)
      appointment_time = date.to_time.change(hour: hour, min: minute)
      create(:service_appointment,
             employee: employee,
             appointment_date: appointment_time,
             duration_minutes: duration,
             **attrs)
    end

    # Helper para criar produto com estoque
    def create_product_with_stock(quantity:, **attrs)
      product = create(:product, **attrs)
      create(:product_input, product: product, quantity: quantity) if quantity > 0
      product.reload
      product
    end

    # Helper para simular login em testes de controller
    def sign_in_user(user = nil)
      user ||= create(:user)
      sign_in user
      user
    end
  end
end

# Configuração do Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

# Configuração do Database Cleaner
require "database_cleaner/active_record"

DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
    include FactoryBot::Syntax::Methods
    include Warden::Test::Helpers

    setup do
      DatabaseCleaner.start
      Warden.test_mode!
    end

    teardown do
      Warden.test_reset!
      DatabaseCleaner.clean
    end

    # Override sign_in para usar Warden diretamente
    def sign_in(resource, scope: nil)
      scope ||= :user
      login_as(resource, scope: scope)
    end

    def sign_out(resource_or_scope)
      scope = resource_or_scope.is_a?(Symbol) ? resource_or_scope : :user
      logout(scope)
    end

    # Gera um CPF válido para testes de integração
    def generate_valid_cpf
      cpf = Array.new(9) { rand(0..9) }

      # Primeiro dígito verificador
      sum = cpf.each_with_index.sum { |digit, index| digit * (10 - index) }
      remainder = sum % 11
      cpf << (remainder < 2 ? 0 : 11 - remainder)

      # Segundo dígito verificador
      sum = cpf.each_with_index.sum { |digit, index| digit * (11 - index) }
      remainder = sum % 11
      cpf << (remainder < 2 ? 0 : 11 - remainder)

      cpf.join
    end
  end
end

# Helpers específicos para testes de sistema
class ActionDispatch::SystemTestCase
  include FactoryBot::Syntax::Methods

  setup do
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end
end
