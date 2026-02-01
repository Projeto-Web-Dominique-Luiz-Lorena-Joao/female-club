# =============================================================================
# CONFIGURAÇÕES DE PERFORMANCE
# =============================================================================

# GARBAGE COLLECTION OTIMIZADO
# Ajusta os parâmetros do GC para aplicações Rails
if Rails.env.production?
  # RUBY_GC_HEAP_INIT_SLOTS: Slots iniciais do heap (evita expansões frequentes)
  ENV['RUBY_GC_HEAP_INIT_SLOTS'] ||= '600000'

  # RUBY_GC_HEAP_FREE_SLOTS: Slots livres após GC
  ENV['RUBY_GC_HEAP_FREE_SLOTS'] ||= '600000'

  # RUBY_GC_HEAP_GROWTH_FACTOR: Fator de crescimento do heap
  ENV['RUBY_GC_HEAP_GROWTH_FACTOR'] ||= '1.25'

  # RUBY_GC_HEAP_GROWTH_MAX_SLOTS: Máximo de slots por expansão
  ENV['RUBY_GC_HEAP_GROWTH_MAX_SLOTS'] ||= '300000'

  # RUBY_GC_MALLOC_LIMIT: Limite para trigger de GC minor
  ENV['RUBY_GC_MALLOC_LIMIT'] ||= '64000000'

  # RUBY_GC_OLDMALLOC_LIMIT: Limite para objetos antigos
  ENV['RUBY_GC_OLDMALLOC_LIMIT'] ||= '64000000'
end

# ACTIVE RECORD OTIMIZAÇÕES
Rails.application.config.after_initialize do
  # Desabilita logs de queries em produção para reduzir I/O
  if Rails.env.production?
    ActiveRecord::Base.logger = nil
  end

  # Cache de schema em produção
  if Rails.env.production?
    ActiveRecord::Base.schema_cache = ActiveRecord::ConnectionAdapters::SchemaCache.new(
      ActiveRecord::Base.connection
    )
  end
end

# MIDDLEWARE DE COMPRESSÃO
# Comprimir respostas maiores que 1KB
Rails.application.config.middleware.use Rack::Deflater if Rails.env.production?

# TIMEOUT PARA QUERIES LONGAS (evita travamentos)
Rails.application.config.after_initialize do
  if Rails.env.production?
    ActiveRecord::Base.connection.execute("SET statement_timeout = '30s'")
  end
rescue StandardError => e
  Rails.logger.warn("Could not set statement_timeout: #{e.message}")
end
