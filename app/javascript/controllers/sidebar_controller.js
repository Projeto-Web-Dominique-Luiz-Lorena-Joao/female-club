import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "arrow", "sidebar", "content", "link", "toggleButton"]
  
  connect() {
    this.collapsed = localStorage.getItem("sidebarCollapsed") === "true"
    this.updateState()
    
    
    this.restoreOpenSubmenus()
  }

  toggle() {
    this.collapsed = !this.collapsed
    localStorage.setItem("sidebarCollapsed", this.collapsed)
    this.updateState()
  }

  toggleSubmenu(event) {
    
    if (this.collapsed) {
      event.preventDefault()
      
      
      this.collapsed = false
      localStorage.setItem("sidebarCollapsed", false)
      this.updateState()
      
      
      setTimeout(() => {
        const submenuId = event.currentTarget.getAttribute("data-submenu-id")
        const submenu = document.getElementById(`${submenuId}-submenu`)
        const parentLink = event.currentTarget
        
        if (submenu) {
          submenu.classList.remove("hidden")
          localStorage.setItem(`submenu-${submenuId}`, "open")
          
          
          parentLink.classList.add("bg-white/10", "text-white")
          parentLink.classList.remove("text-gray-300")
          
          
          const arrow = parentLink.querySelector("svg:last-child")
          if (arrow) {
            arrow.classList.add("rotate-180")
          }
        }
      }, 200)
      
      return
    }
    
    
    event.preventDefault()

    const submenuId = event.currentTarget.getAttribute("data-submenu-id")
    const submenu = document.getElementById(`${submenuId}-submenu`)
    const parentLink = event.currentTarget

    if (submenu) {
      const isHidden = submenu.classList.contains("hidden")
      submenu.classList.toggle("hidden")

      
      if (isHidden) {
        parentLink.classList.add("bg-white/10", "text-white")
        parentLink.classList.remove("text-gray-300")
        localStorage.setItem(`submenu-${submenuId}`, "open")
      } else {
        parentLink.classList.remove("bg-white/10", "text-white")
        parentLink.classList.add("text-gray-300")
        localStorage.removeItem(`submenu-${submenuId}`)
      }

      
      const arrow = event.currentTarget.querySelector("svg:last-child")
      if (arrow) {
        arrow.classList.toggle("rotate-180")
      }
    }
  }

  restoreOpenSubmenus() {
    
    const keys = Object.keys(localStorage)
    keys.forEach(key => {
      if (key.startsWith("submenu-") && localStorage.getItem(key) === "open") {
        const submenuId = key.replace("submenu-", "")
        const submenu = document.getElementById(`${submenuId}-submenu`)
        
        if (submenu && !this.collapsed) {
          submenu.classList.remove("hidden")
          
          
          const parentButton = document.querySelector(`[data-submenu-id="${submenuId}"]`)
          if (parentButton) {
            const arrow = parentButton.querySelector("svg:last-child")
            if (arrow) {
              arrow.classList.add("rotate-180")
            }
            parentButton.classList.add("bg-white/10", "text-white")
            parentButton.classList.remove("text-gray-300")
          }
        }
      }
    })
  }

  updateState() {
    if (this.collapsed) {
      
      document.documentElement.classList.add('sidebar-collapsed')
      
      this.sidebarTarget.classList.remove("w-72")
      this.sidebarTarget.classList.add("w-20")
      
      this.contentTarget.classList.remove("ml-72")
      this.contentTarget.classList.add("ml-20")
      
      
      this.toggleButtonTarget.classList.remove("left-[268px]")
      this.toggleButtonTarget.classList.add("left-[68px]")
      
      
      this.textTargets.forEach(el => {
        el.classList.add("opacity-0", "max-w-0", "invisible", "pointer-events-none")
      })
      
      
      document.querySelectorAll('[id$="-submenu"]').forEach(submenu => {
        submenu.classList.add("hidden")
        
        const arrow = submenu.previousElementSibling?.querySelector("svg:last-child")
        if (arrow) {
          arrow.classList.remove("rotate-180")
        }
        const parentLink = submenu.previousElementSibling
        if (parentLink) {
          parentLink.classList.remove("bg-white/10", "text-white")
          parentLink.classList.add("text-gray-300")
        }
      })
      
      this.arrowTarget.classList.add("rotate-180")
    } else {
      
      document.documentElement.classList.remove('sidebar-collapsed')
      
      this.sidebarTarget.classList.remove("w-20")
      this.sidebarTarget.classList.add("w-72")
      
      this.contentTarget.classList.remove("ml-20")
      this.contentTarget.classList.add("ml-72")
      
      
      this.toggleButtonTarget.classList.remove("left-[68px]")
      this.toggleButtonTarget.classList.add("left-[268px]")
      
      
      setTimeout(() => {
        this.textTargets.forEach(el => {
          el.classList.remove("opacity-0", "max-w-0", "invisible", "pointer-events-none")
        })
      }, 100)
      
      
      setTimeout(() => {
        this.restoreOpenSubmenus()
      }, 150)
      
      this.arrowTarget.classList.remove("rotate-180")
    }
  }
}