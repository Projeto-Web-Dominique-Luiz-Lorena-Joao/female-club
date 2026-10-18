require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.headers = {
    "cache-control" => "public, max-age=#{1.year.to_i}, immutable",
    "vary" => "Accept-Encoding"
  }

  # Active Storage - "local" no teste (fotos se perdem ao reiniciar);
  # "cloudflare" quando o R2 estiver configurado
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  config.assume_ssl = true
  config.force_ssl = true

  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  # Cache e Jobs em memória (instância única no Render).
  # Migrar para Solid Cache/Queue depois, com bancos dedicados.
  config.cache_store = :memory_store
  config.active_job.queue_adapter = :async

  # Mailer - só envia se as credenciais SMTP estiverem configuradas.
  # Obs.: o plano free do Render bloqueia as portas SMTP (25/465/587).
  smtp_configurado = ENV["SMTP_USERNAME"].present? && ENV["SMTP_PASSWORD"].present?
  config.action_mailer.perform_deliveries = smtp_configurado
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "female-club.onrender.com"), protocol: "https" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS", "smtp.gmail.com"),
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    domain: ENV.fetch("SMTP_DOMAIN", "gmail.com"),
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true
  }

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
end
