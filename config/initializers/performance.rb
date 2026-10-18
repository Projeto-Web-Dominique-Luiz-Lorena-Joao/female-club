# =============================================================================
# CONFIGURAÇÕES DE PERFORMANCE
# =============================================================================
#
# Notas:
# - Cache de schema: o Rails 8 já faz automaticamente (use_schema_cache_dump).
# - Timeout de queries: configurado em config/database.yml (variables.statement_timeout),
#   assim vale para todas as conexões do pool.
# - Ajustes de GC (RUBY_GC_*) só funcionam como variáveis de ambiente do servidor,
#   definidas antes do Ruby iniciar — não dentro de um initializer.

# MIDDLEWARE DE COMPRESSÃO
# Comprime as respostas HTTP em produção (gzip)
Rails.application.config.middleware.use Rack::Deflater if Rails.env.production?
