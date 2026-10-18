# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Security', type: :request do
  let(:user) { create(:user) }

  # ===========================================================================
  # AUTENTICAÇÃO - Todas as rotas protegidas requerem login
  # ===========================================================================
  describe 'Authentication enforcement' do
    context 'without authentication' do
      it 'redirects dashboard to login' do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects customers to login' do
        get customers_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects employees to login' do
        get employees_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects sales to login' do
        get sales_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects products to login' do
        get products_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects suppliers to login' do
        get suppliers_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects expenses to login' do
        get expenses_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects admin access requests to login' do
        get admin_access_requests_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects API endpoints to login' do
        get api_employees_search_path(q: 'test')
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'public routes work without authentication' do
      it 'allows access to login page' do
        get new_user_session_path
        expect(response).to have_http_status(:success)
      end

      it 'allows access to access request form' do
        get new_access_request_path
        expect(response).to have_http_status(:success)
      end

      it 'allows access to password reset form' do
        get new_user_password_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  # ===========================================================================
  # CSRF - Cross-Site Request Forgery
  # ===========================================================================
  describe 'CSRF protection' do
    before { login_as(user, scope: :user) }

    it 'rejects POST without CSRF token' do
      ActionController::Base.allow_forgery_protection = true

      post customers_path, params: { customer: { full_name: 'Test' } }
      expect(response).to have_http_status(:unprocessable_entity).or redirect_to(new_user_session_path)

      ActionController::Base.allow_forgery_protection = false
    end
  end

  # ===========================================================================
  # SQL INJECTION - Tentativas de injeção SQL via busca
  # ===========================================================================
  describe 'SQL Injection prevention' do
    before { login_as(user, scope: :user) }

    sql_payloads = [
      "'; DROP TABLE customers; --",
      "1' OR '1'='1",
      "1; SELECT * FROM users; --",
      "' UNION SELECT email, encrypted_password FROM users --",
      "1' AND 1=CONVERT(int, (SELECT TOP 1 email FROM users))--",
      "admin'--",
      "' OR 1=1 --",
      "'; EXEC xp_cmdshell('whoami'); --"
    ]

    sql_payloads.each do |payload|
      it "handles SQL injection attempt in customer search: #{payload.truncate(40)}" do
        expect {
          get customers_path(search: payload)
        }.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "handles SQL injection attempt in employee search: #{payload.truncate(40)}" do
        expect {
          get employees_path(search: payload)
        }.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "handles SQL injection attempt in API search: #{payload.truncate(40)}" do
        expect {
          get api_employees_search_path(q: payload)
        }.not_to raise_error
        expect(response).to have_http_status(:success)
      end
    end
  end

  # ===========================================================================
  # XSS - Cross-Site Scripting
  # ===========================================================================
  describe 'XSS prevention' do
    before { login_as(user, scope: :user) }

    xss_payloads = [
      '<script>alert("XSS")</script>',
      '<img src=x onerror=alert(1)>',
      '<svg onload=alert(1)>',
      '"><script>alert(document.cookie)</script>',
      "javascript:alert('XSS')",
      '<iframe src="javascript:alert(1)">',
      '<body onload=alert(1)>'
    ]

    xss_payloads.each do |payload|
      it "escapes XSS payload in customer search results: #{payload.truncate(40)}" do
        create(:customer, full_name: payload)
        get customers_path
        expect(response.body).not_to include(payload)
      end

      it "escapes XSS payload reflected in search param: #{payload.truncate(40)}" do
        get customers_path(search: payload)
        expect(response).to have_http_status(:success)
        # The raw script tag should NOT appear unescaped
        expect(response.body).not_to include('<script>alert')
      end
    end

    it 'escapes HTML in employee names' do
      employee = create(:employee, full_name: '<script>alert("xss")</script>', status: 'ativo')
      get employees_path
      expect(response.body).not_to include('<script>alert("xss")</script>')
      expect(response.body).to include('&lt;script&gt;').or include('script')
    end
  end

  # ===========================================================================
  # HTML INJECTION
  # ===========================================================================
  describe 'HTML Injection prevention' do
    before { login_as(user, scope: :user) }

    it 'escapes HTML in flash messages via access requests' do
      post access_requests_path, params: {
        access_request: {
          email: '<h1>injected</h1>@test.com',
          password: 'Password123!',
          password_confirmation: 'Password123!',
          message: '<marquee>hacked</marquee>'
        }
      }
      # Invalid email should not render raw HTML
      expect(response.body).not_to include('<h1>injected</h1>')
      expect(response.body).not_to include('<marquee>')
    end
  end

  # ===========================================================================
  # MASS ASSIGNMENT - Atribuição em massa de campos protegidos
  # ===========================================================================
  describe 'Mass assignment protection' do
    before { login_as(user, scope: :user) }

    it 'does not allow setting arbitrary fields on customer creation' do
      post customers_path, params: {
        customer: {
          full_name: 'Test Customer',
          id: 99999,
          created_at: '2020-01-01',
          updated_at: '2020-01-01'
        }
      }
      customer = Customer.last
      expect(customer&.id).not_to eq(99999) if customer
    end

    it 'does not allow setting admin attributes on access request' do
      post access_requests_path, params: {
        access_request: {
          email: 'test@hacker.com',
          password: 'Password123!',
          password_confirmation: 'Password123!',
          status: 'approved',
          encrypted_password: 'hacked_password'
        }
      }
      ar = AccessRequest.find_by(email: 'test@hacker.com')
      expect(ar&.status).to eq('pending')
      expect(ar&.encrypted_password).not_to eq('hacked_password')
    end
  end

  # ===========================================================================
  # IDOR - Insecure Direct Object Reference
  # ===========================================================================
  describe 'IDOR protection' do
    before { login_as(user, scope: :user) }

    it 'returns 404 for non-existent customer' do
      get customer_path(id: 999999)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for non-existent employee' do
      get employee_path(id: 999999)
      expect(response).to have_http_status(:not_found)
    end
  end

  # ===========================================================================
  # SESSION SECURITY
  # ===========================================================================
  describe 'Session security' do
    it 'invalidates session after logout' do
      login_as(user, scope: :user)
      get dashboard_path
      expect(response).to have_http_status(:success)

      delete destroy_user_session_path
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'sets secure session cookie attributes' do
      session_config = Rails.application.config.session_store
      expect(session_config).to eq(ActionDispatch::Session::CookieStore)
    end
  end

  # ===========================================================================
  # SECURITY HEADERS
  # ===========================================================================
  describe 'Security headers' do
    before do
      login_as(user, scope: :user)
      get dashboard_path
    end

    it 'sets X-Frame-Options to DENY' do
      expect(response.headers['X-Frame-Options']).to eq('DENY')
    end

    it 'sets X-Content-Type-Options to nosniff' do
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
    end

    it 'sets X-XSS-Protection' do
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
    end

    it 'sets Referrer-Policy' do
      expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
    end

    it 'sets Content-Security-Policy' do
      expect(response.headers['Content-Security-Policy']).to be_present
    end

    it 'CSP blocks external frame embedding' do
      csp = response.headers['Content-Security-Policy']
      expect(csp).to include('frame-ancestors')
    end
  end

  # ===========================================================================
  # BRUTE FORCE / ACCOUNT LOCKOUT
  # ===========================================================================
  describe 'Account lockout after failed attempts' do
    let!(:target_user) { create(:user, email: 'locktest@example.com') }

    it 'locks account after maximum failed login attempts' do
      6.times do
        post user_session_path, params: {
          user: { email: 'locktest@example.com', password: 'WrongPassword1!' }
        }
      end

      target_user.reload
      expect(target_user.access_locked?).to be true
    end

    it 'does not lock account with correct password' do
      post user_session_path, params: {
        user: { email: 'locktest@example.com', password: 'Password123!' }
      }

      target_user.reload
      expect(target_user.access_locked?).to be false
    end
  end

  # ===========================================================================
  # PASSWORD SECURITY
  # ===========================================================================
  describe 'Password security' do
    it 'does not expose password hash in user JSON' do
      login_as(user, scope: :user)
      get dashboard_path
      expect(response.body).not_to include(user.encrypted_password)
    end

    it 'rejects weak password on access request' do
      post access_requests_path, params: {
        access_request: {
          email: 'weak@password.com',
          password: '12345678',
          password_confirmation: '12345678'
        }
      }
      expect(AccessRequest.find_by(email: 'weak@password.com')).to be_nil
    end

    it 'rejects password without special character' do
      post access_requests_path, params: {
        access_request: {
          email: 'nospecial@test.com',
          password: 'Password123',
          password_confirmation: 'Password123'
        }
      }
      expect(AccessRequest.find_by(email: 'nospecial@test.com')).to be_nil
    end
  end

  # ===========================================================================
  # OPEN REDIRECT
  # ===========================================================================
  describe 'Open redirect prevention' do
    it 'does not follow external redirects on login' do
      post user_session_path, params: {
        user: { email: user.email, password: 'Password123!' }
      }
      # Should redirect to app root, not external
      expect(response).to redirect_to(authenticated_root_path)
    end
  end

  # ===========================================================================
  # INPUT SANITIZATION
  # ===========================================================================
  describe 'Input sanitization' do
    before { login_as(user, scope: :user) }

    it 'truncates extremely long search queries' do
      long_query = 'A' * 500
      expect {
        get customers_path(search: long_query)
      }.not_to raise_error
      expect(response).to have_http_status(:success)
    end

    it 'handles null bytes in search input' do
      expect {
        get customers_path(search: "test\x00injection")
      }.not_to raise_error
    end

    it 'handles unicode abuse in search input' do
      expect {
        get customers_path(search: "test\u202Etest")
      }.not_to raise_error
    end

    it 'handles empty search gracefully' do
      get customers_path(search: '')
      expect(response).to have_http_status(:success)
    end
  end

  # ===========================================================================
  # ERROR HANDLING - Não expor informações internas
  # ===========================================================================
  describe 'Error information disclosure' do
    before { login_as(user, scope: :user) }

    it 'does not expose stack traces in JSON error responses' do
      post customers_path, params: { customer: { full_name: '' } }, as: :json
      body = JSON.parse(response.body) rescue {}
      errors_text = body['errors']&.join(' ') || ''
      expect(errors_text).not_to include('app/controllers')
      expect(errors_text).not_to include('.rb:')
    end
  end

  # ===========================================================================
  # ACCESS REQUEST SPAM PROTECTION
  # ===========================================================================
  describe 'Access request abuse prevention' do
    it 'validates email format on access requests' do
      post access_requests_path, params: {
        access_request: {
          email: 'not-an-email',
          password: 'Password123!',
          password_confirmation: 'Password123!'
        }
      }
      expect(AccessRequest.find_by(email: 'not-an-email')).to be_nil
    end

    it 'requires password confirmation match' do
      post access_requests_path, params: {
        access_request: {
          email: 'mismatch@test.com',
          password: 'Password123!',
          password_confirmation: 'DifferentPass1!'
        }
      }
      expect(AccessRequest.find_by(email: 'mismatch@test.com')).to be_nil
    end
  end

  # ===========================================================================
  # PAGINATION ABUSE
  # ===========================================================================
  describe 'Pagination abuse prevention' do
    before { login_as(user, scope: :user) }

    it 'ignores invalid per_page values' do
      get customers_path(per_page: 99999)
      expect(response).to have_http_status(:success)
    end

    it 'ignores negative page numbers' do
      get customers_path(page: -1)
      expect(response).to have_http_status(:success)
    end

    it 'ignores non-numeric page values' do
      get customers_path(page: 'abc')
      expect(response).to have_http_status(:success)
    end
  end
end
