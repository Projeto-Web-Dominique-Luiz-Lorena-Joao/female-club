# frozen_string_literal: true

require 'capybara/rspec'

# Configuração do driver padrão
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless

# Configurações adicionais
Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
  config.automatic_label_click = true
  config.enable_aria_label = true
end

# Driver para testes com JavaScript (headless)
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by(:rack_test)
  end

  config.before(:each, type: :system, js: true) do
    driven_by(:selenium_chrome_headless)
  end
end

# Helpers para testes de sistema
module SystemTestHelpers
  def login_user(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Senha', with: 'Password123!'
    click_button 'Entrar'
  end

  def logout_user
    click_link 'Sair' if has_link?('Sair')
  end

  def within_main_content(&block)
    within('main', &block)
  end

  def wait_for_turbo
    sleep 0.1
  end
end

RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system
end
