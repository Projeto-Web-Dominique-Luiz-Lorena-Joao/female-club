module ApplicationHelper
  # Para links normais
  def active_class(path)
    current_page?(path) ?
      "bg-white text-black" :
      "text-gray-300 hover:bg-white/10 hover:text-white"
  end

  # Para submenus (pode receber várias rotas)
  def active_submenu?(*paths)
    paths.any? { |p| current_page?(p) }
  end
end
