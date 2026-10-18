# frozen_string_literal: true

# =============================================================================
# RACK ATTACK - PROTEÇÃO CONTRA DDOS E BRUTE FORCE
# =============================================================================

class Rack::Attack
  # Cache store - usar o cache do Rails
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # =============================================================================
  # SAFELIST (IPs permitidos - nunca bloqueados)
  # =============================================================================

  # Permitir sempre requisições de localhost
  safelist("allow-localhost") do |req|
    "127.0.0.1" == req.ip || "::1" == req.ip
  end

  # =============================================================================
  # THROTTLE (Limitação de taxa)
  # =============================================================================

  # Limitar requisições gerais por IP (300 req/5min)
  # Proteção contra DDoS básico
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Limitar tentativas de login por IP (5 tentativas/20seg)
  # Proteção contra brute force
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Limitar tentativas de login por email (5 tentativas/min)
  # Proteção contra brute force direcionado
  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalizar email para lowercase
      req.params["user"]["email"].to_s.downcase.gsub(/\s+/, "") if req.params["user"]
    end
  end

  # Limitar tentativas de recuperação de senha (3 tentativas/hora)
  throttle("password_resets/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  # Limitar criação de registros por IP (10/min)
  # Proteção contra spam/abuso
  throttle("creates/ip", limit: 10, period: 1.minute) do |req|
    if req.post? && !req.path.start_with?("/users")
      req.ip
    end
  end

  # Limitar solicitações de acesso (3/hora por IP)
  # Proteção contra spam de solicitações
  throttle("access_requests/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/access_requests" && req.post?
      req.ip
    end
  end

  # Limitar buscas na API (30/min por IP)
  # Proteção contra enumeração de dados
  throttle("api_search/ip", limit: 30, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  # =============================================================================
  # BLOCKLIST (IPs bloqueados)
  # =============================================================================

  # Bloquear IPs com comportamento suspeito (opcional - ativar se necessário)
  # blocklist('block-suspicious') do |req|
  #   Rack::Attack::Fail2Ban.filter("fail2ban-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
  #     req.path == '/users/sign_in' && req.post?
  #   end
  # end

  # =============================================================================
  # RESPOSTAS CUSTOMIZADAS
  # =============================================================================

  # Resposta para requisições bloqueadas por throttle
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429, # Too Many Requests
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ {
        error: "Muitas requisições. Por favor, aguarde um momento antes de tentar novamente.",
        retry_after: retry_after
      }.to_json ]
    ]
  end

  # Resposta para requisições bloqueadas por blocklist
  self.blocklisted_responder = lambda do |request|
    [
      403, # Forbidden
      { "Content-Type" => "application/json" },
      [ { error: "Acesso bloqueado temporariamente devido a comportamento suspeito." }.to_json ]
    ]
  end
end

# Habilitar Rack::Attack no middleware
Rails.application.config.middleware.use Rack::Attack

# Logging de eventos (útil para monitoramento)
ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
  req = payload[:request]

  if [ :throttle, :blocklist ].include?(req.env["rack.attack.match_type"])
    Rails.logger.warn(
      "[Rack::Attack] #{req.env['rack.attack.match_type']} " \
      "#{req.env['rack.attack.matched']} " \
      "#{req.ip} " \
      "#{req.request_method} #{req.fullpath}"
    )
  end
end
