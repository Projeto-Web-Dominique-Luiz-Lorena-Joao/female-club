import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "arrow", "sidebar", "content", "link"]
  
  connect() {
    this.collapsed = localStorage.getItem("sidebarCollapsed") === "true"
    this.updateState()
  }

  toggle() {
    this.collapsed = !this.collapsed
    localStorage.setItem("sidebarCollapsed", this.collapsed)
    this.updateState()
  }

  toggleSubmenu(event) {
    const submenuId = event.currentTarget.getAttribute("data-submenu-id")
    const submenu = document.getElementById(`${submenuId}-submenu`)

    if (submenu) {
      submenu.classList.toggle("hidden")

      // Rotate the arrow icon
      const arrow = event.currentTarget.querySelector("svg:last-child")
      if (arrow) {
        arrow.classList.toggle("rotate-180")
      }
    }
  }

  updateState() {
    if (this.collapsed) {
      this.sidebarTarget.classList.remove("w-72")
      this.sidebarTarget.classList.add("w-20")
      
      this.contentTarget.classList.remove("ml-72")
      this.contentTarget.classList.add("ml-20")
      
      // Adiciona delay antes de esconder os textos
      setTimeout(() => {
        this.textTargets.forEach(el => {
          el.classList.add("opacity-0")
        })
      }, 100)
      
      setTimeout(() => {
        this.textTargets.forEach(el => {
          el.classList.add("hidden")
        })
      }, 300)
      
      this.arrowTarget.classList.add("rotate-180")
    } else {
      this.sidebarTarget.classList.remove("w-20")
      this.sidebarTarget.classList.add("w-72")
      
      this.contentTarget.classList.remove("ml-20")
      this.contentTarget.classList.add("ml-72")
      
      // Remove hidden primeiro, depois faz fade in
      this.textTargets.forEach(el => {
        el.classList.remove("hidden")
      })
      
      setTimeout(() => {
        this.textTargets.forEach(el => {
          el.classList.remove("opacity-0")
        })
      }, 100)
      
      this.arrowTarget.classList.remove("rotate-180")
    }
  }
}