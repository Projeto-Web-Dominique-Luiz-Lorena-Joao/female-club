module ApplicationHelper
  def active_class(path)
    if current_page?(path)
      "bg-white text-black"
    else
      "text-gray-300 hover:bg-white/10 hover:text-white"
    end
  end
end
