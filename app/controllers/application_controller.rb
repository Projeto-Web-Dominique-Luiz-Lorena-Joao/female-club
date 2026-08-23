class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # SEGURANÇA: Exigir autenticação em todas as rotas por padrão
  before_action :authenticate_user!

  layout :set_layout

  # Action pública para atualizar preferência de paginação
  def update_pagination_preference
    if user_signed_in?
      items = params[:items_per_page].presence

      if items.nil?
        # Se for nil, remove a preferência (volta ao padrão do sistema)
        current_user.update(items_per_page: nil)
      else
        # Atualiza com o valor escolhido
        current_user.update(items_per_page: items.to_i)
      end
    end

    redirect_back(fallback_location: root_path)
  end

  private

  def set_layout
    if devise_controller? && controller_name != "registrations"
      "devise"
    else
      "application"
    end
  end

  # SEGURANÇA: Sanitizar e limitar tamanho de parâmetros de busca
  def sanitize_search(term, max_length: 100)
    return nil if term.blank?

    term.to_s.gsub("\x00", "").strip.truncate(max_length, omission: "")
  end

  # Converte parâmetro de data com segurança, retornando nil se inválido
  # ao invés de lançar Date::Error (evita erro 500 em filtros de período)
  def parse_filter_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue Date::Error, TypeError
    nil
  end

  # Torna per_page disponível como helper para as views
  helper_method :per_page

  def per_page
    # Se o usuário especificou no parâmetro, usa esse valor
    if params[:per_page].present?
      per = params[:per_page].to_i
      return per if [ 10, 15, 20, 25, 50 ].include?(per)
    end

    # Caso contrário, usa a preferência do usuário logado
    if user_signed_in? && current_user.items_per_page.present?
      return current_user.items_per_page
    end

    # Default: 15
    15
  end
end
