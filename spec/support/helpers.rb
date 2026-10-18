# frozen_string_literal: true

module TestHelpers
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
  def generate_unique_email(prefix = 'test')
    "#{prefix}_#{SecureRandom.hex(8)}@example.com"
  end

  # Gera um telefone válido brasileiro
  def generate_valid_phone
    "11#{rand(900_000_000..999_999_999)}"
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
