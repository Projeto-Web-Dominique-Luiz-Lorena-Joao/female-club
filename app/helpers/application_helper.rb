module ApplicationHelper
  # Para links normais
  def active_class(path)
    current_section?(path) ?
      "bg-white text-black" :
      "text-gray-300 hover:bg-white/10 hover:text-white"
  end

  # Para itens de submenu (mesmo destaque do active_class, mas com estilos menores)
  def active_submenu_class(path)
    current_section?(path) ?
      "bg-white text-black" :
      "text-gray-400 hover:bg-white/5 hover:text-white"
  end

  # Para submenus (pode receber várias rotas)
  def active_submenu?(*paths)
    paths.any? { |p| current_section?(p) }
  end

  # Considera ativa tanto a própria rota (ex: /customers) quanto suas
  # sub-páginas (ex: /customers/5, /customers/5/edit), já que current_page?
  # exige correspondência exata e "desmarcava" o menu ao entrar em detalhe/edição.
  def current_section?(path)
    request.path == path || request.path.start_with?("#{path}/")
  end

  # SEGURANÇA: Helper para sanitizar dados antes de renderizar em JSON/JavaScript
  # Previne XSS em dados que serão inseridos no DOM
  def safe_json(data)
    # ERB::Util.json_escape é seguro para inserção em contextos JavaScript
    ERB::Util.json_escape(data.to_json)
  end

  # SEGURANÇA: Sanitiza string para uso seguro em HTML
  def sanitize_for_display(text)
    return "" if text.blank?
    ERB::Util.html_escape(text.to_s)
  end
end
