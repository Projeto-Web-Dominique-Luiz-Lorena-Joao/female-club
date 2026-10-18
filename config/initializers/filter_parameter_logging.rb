# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.

# SEGURANÇA: Filtrar todos os dados sensíveis dos logs
Rails.application.config.filter_parameters += [
  # Autenticação
  :passw, :password, :password_confirmation,
  :secret, :token, :_key, :auth,

  # Dados pessoais (LGPD)
  :cpf, :cnpj, :rg,
  :email,
  :phone, :phone_number, :telefone, :celular,
  :birth_date, :data_nascimento,

  # Dados financeiros
  :credit_card, :card_number, :cvv, :cvc,
  :bank_account, :conta_bancaria,
  :salary, :salario,

  # Criptografia
  :crypt, :salt, :certificate, :otp, :ssn,

  # Endereço
  :address, :endereco, :full_address, :cep
]
