# frozen_string_literal: true

# SimpleCov deve ser carregado ANTES de qualquer outro código
require 'simplecov'
SimpleCov.start 'rails' do
  command_name 'RSpec'
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/db/'

  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Jobs', 'app/jobs'

  enable_coverage :branch
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'capybara/rspec'
require 'database_cleaner/active_record'

# Carregar arquivos de suporte
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Verificar migrações pendentes
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Devise helpers para testes de request/controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Warden::Test::Helpers

  # Fixtures
  config.fixture_paths = [ Rails.root.join('spec/fixtures') ]

  # Transações para testes
  config.use_transactional_fixtures = true

  # Inferir tipo de spec baseado na localização
  config.infer_spec_type_from_file_location!

  # Filtrar backtrace do Rails
  config.filter_rails_from_backtrace!

  # Database Cleaner
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Warden.test_reset!
  end

  # Limpar cache entre testes
  config.before(:each) do
    Rails.cache.clear
  end
end

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Configuração do Capybara
Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
end
