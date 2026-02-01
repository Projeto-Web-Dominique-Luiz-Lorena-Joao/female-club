# =============================================================================
# CONFIGURAÇÃO DE CACHE EM MÚLTIPLAS CAMADAS
# =============================================================================

Rails.application.configure do
  # Em desenvolvimento, usar memory store para testes rápidos
  if Rails.env.development?
    config.cache_store = :memory_store, {
      size: 64.megabytes,
      expires_in: 1.hour
    }
  end

  # Cache de queries do ActiveRecord
  config.active_record.cache_versioning = true

  # Cache de templates
  config.action_view.cache_template_loading = !Rails.env.development?
end

# =============================================================================
# HELPER METHODS PARA CACHE
# =============================================================================
module CacheHelper
  extend self

  # Cache keys com versionamento automático
  def versioned_key(base_key, *dependencies)
    version = dependencies.map do |dep|
      case dep
      when ActiveRecord::Base
        "#{dep.class.name}-#{dep.id}-#{dep.updated_at.to_i}"
      when ActiveRecord::Relation
        dep.cache_key_with_version
      when Class
        dep.maximum(:updated_at)&.to_i || 0
      else
        dep.to_s
      end
    end.join('-')

    "#{base_key}/#{Digest::MD5.hexdigest(version)}"
  end

  # Cache com fallback
  def fetch_with_fallback(key, options = {}, &block)
    Rails.cache.fetch(key, options, &block)
  rescue StandardError => e
    Rails.logger.warn("Cache error: #{e.message}")
    yield if block_given?
  end

  # Invalidar cache por padrão
  def invalidate_pattern(pattern)
    Rails.cache.delete_matched(pattern)
  rescue NotImplementedError
    Rails.logger.warn("Cache store doesn't support delete_matched")
  end
end

# =============================================================================
# CACHE DE CONTADORES FREQUENTES
# =============================================================================
module CounterCache
  extend self

  COUNTER_EXPIRY = 5.minutes

  def customers_count
    Rails.cache.fetch('stats/customers_count', expires_in: COUNTER_EXPIRY) do
      Customer.count
    end
  end

  def active_employees_count
    Rails.cache.fetch('stats/active_employees_count', expires_in: COUNTER_EXPIRY) do
      Employee.where(status: 'active').count
    end
  end

  def active_services_count
    Rails.cache.fetch('stats/active_services_count', expires_in: COUNTER_EXPIRY) do
      Service.where(active: true).count
    end
  end

  def products_low_stock_count
    Rails.cache.fetch('stats/products_low_stock_count', expires_in: COUNTER_EXPIRY) do
      Product.low_stock.count
    end
  end

  def today_appointments_count
    Rails.cache.fetch("stats/today_appointments_#{Date.today}", expires_in: COUNTER_EXPIRY) do
      ServiceAppointment.where(appointment_date: Date.today.all_day).count
    end
  end

  # Invalidar todos os contadores
  def invalidate_all
    %w[
      stats/customers_count
      stats/active_employees_count
      stats/active_services_count
      stats/products_low_stock_count
    ].each { |key| Rails.cache.delete(key) }
    Rails.cache.delete("stats/today_appointments_#{Date.today}")
  end
end

# =============================================================================
# CALLBACKS PARA INVALIDAR CACHE AUTOMATICAMENTE
# =============================================================================
Rails.application.config.after_initialize do
  # Invalidar cache de clientes quando um cliente é criado/atualizado/deletado
  Customer.after_commit { Rails.cache.delete('stats/customers_count') }

  # Invalidar cache de funcionários
  Employee.after_commit { Rails.cache.delete('stats/active_employees_count') }

  # Invalidar cache de serviços
  Service.after_commit { Rails.cache.delete('stats/active_services_count') }

  # Invalidar cache de produtos
  Product.after_commit { Rails.cache.delete('stats/products_low_stock_count') }

  # Invalidar cache de agendamentos do dia
  ServiceAppointment.after_commit do
    Rails.cache.delete("stats/today_appointments_#{Date.today}")
  end
end
