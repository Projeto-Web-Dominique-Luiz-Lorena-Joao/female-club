# =============================================================================
# CONFIGURAÇÃO OTIMIZADA DO PUMA
# Balanceamento entre throughput, latência e uso de recursos
# =============================================================================

# THREADS
# - Mínimo de threads para resposta rápida em baixa carga
# - Máximo de threads para throughput em alta carga
# - Rails é I/O bound, então mais threads ajudam
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# WORKERS (processos)
# - Cada worker é um processo separado com seu próprio GVL
# - Recomendado: número de CPUs disponíveis (ou CPUs - 1 para deixar CPU para SO)
# - Em produção, use WEB_CONCURRENCY para definir
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# PRELOAD
# - Carrega a aplicação antes de fazer fork dos workers
# - Reduz uso de memória (copy-on-write)
# - Melhora tempo de boot dos workers
preload_app!

# WORKER TIMEOUT
# - Tempo máximo para um worker responder antes de ser reiniciado
worker_timeout ENV.fetch("PUMA_WORKER_TIMEOUT", 60).to_i

# PERSISTENT TIMEOUT
# - Tempo para manter conexões keep-alive abertas
persistent_timeout 20

# FIRST DATA TIMEOUT
# - Tempo máximo para receber o primeiro byte de dados
first_data_timeout 30

# PORT
port ENV.fetch("PORT", 3000)

# PLUGINS
plugin :tmp_restart
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# PID FILE
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# HOOKS
# Antes de fazer fork, fecha conexões do processo mestre
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# Depois de fazer fork, reconecta cada worker
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Garbage Collection otimizado antes de fork (reduz memória copiada)
on_worker_fork do
  GC.start
end

# Log quando worker é iniciado
on_worker_boot do |worker_index|
  puts "=> Puma worker #{worker_index} booted"
end

# LOWLEVEL ERROR HANDLER
# Evita que erros de baixo nível travem o servidor
lowlevel_error_handler do |e, env, status|
  message = "Puma caught error: #{e.class} - #{e.message}"
  Rails.logger.error(message) if defined?(Rails)
  [ 500, {}, [ "Internal Server Error" ] ]
end
