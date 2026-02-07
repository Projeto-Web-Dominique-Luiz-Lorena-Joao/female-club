# frozen_string_literal: true

# =============================================================================
# CONFIGURAÇÕES DE SEGURANÇA DO SISTEMA
# =============================================================================

# Configurar cookies seguros em produção
Rails.application.config.session_store :cookie_store,
  key: "_female_club_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax

# Força SSL em produção
Rails.application.config.force_ssl = Rails.env.production?

# Configurar Content Security Policy (CSP) para prevenir XSS
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :data, "https://fonts.gstatic.com"
  policy.img_src     :self, :data, :blob
  policy.object_src  :none
  policy.script_src  :self, :unsafe_inline, :unsafe_eval, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"  # unsafe necessário para Turbo/Stimulus, jsdelivr para Chart.js, cdnjs para Cropper.js
  policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
  policy.connect_src :self, "https://brasilapi.com.br", "https://cdn.jsdelivr.net"  # API de feriados e Chart.js sourcemaps
  policy.frame_ancestors :none
  policy.base_uri    :self
  policy.form_action :self

  # Reportar violações (opcional - configurar endpoint)
  # policy.report_uri "/csp-violation-report-endpoint"
end

# Nonce desabilitado para permitir unsafe-inline funcionar
# (nonce e unsafe-inline são mutuamente exclusivos - quando nonce está ativo, unsafe-inline é ignorado)
# Rails.application.config.content_security_policy_nonce_generator = ->(request) {
#   SecureRandom.base64(16)
# }

# Headers de segurança adicionais
Rails.application.config.action_dispatch.default_headers = {
  "X-Frame-Options" => "DENY",
  "X-Content-Type-Options" => "nosniff",
  "X-XSS-Protection" => "1; mode=block",
  "X-Download-Options" => "noopen",
  "X-Permitted-Cross-Domain-Policies" => "none",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Permissions-Policy" => "geolocation=(), microphone=(), camera=()"
}
