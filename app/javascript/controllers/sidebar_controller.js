import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "arrow", "sidebar", "content", "link", "overlay", "mobileToggle"]

  connect() {
    this.collapsed = localStorage.getItem("sidebarCollapsed") === "true"
    this.mobileOpen = false
    this.checkScreenSize()
    this.updateState()

    // Listener para resize da janela
    this.resizeHandler = this.checkScreenSize.bind(this)
    window.addEventListener('resize', this.resizeHandler)
  }

  disconnect() {
    window.removeEventListener('resize', this.resizeHandler)
  }

  checkScreenSize() {
    this.isMobile = window.innerWidth < 1024 // lg breakpoint
    this.isTablet = window.innerWidth >= 768 && window.innerWidth < 1024
    this.isDesktop = window.innerWidth >= 1024
    this.isLargeScreen = window.innerWidth >= 1536 // 2xl breakpoint

    if (this.isMobile) {
      // Em mobile, sidebar começa fechada
      this.sidebarTarget.classList.remove("w-72", "w-20")
      this.sidebarTarget.classList.add("w-72", "-translate-x-full")
      this.contentTarget.classList.remove("ml-72", "ml-20", "lg:ml-72", "lg:ml-20")
      this.contentTarget.classList.add("ml-0")

      // Mostrar botão mobile
      if (this.hasMobileToggleTarget) {
        this.mobileToggleTarget.classList.remove("hidden")
      }
    } else {
      // Em desktop, comportamento normal
      this.sidebarTarget.classList.remove("-translate-x-full")
      if (this.hasMobileToggleTarget) {
        this.mobileToggleTarget.classList.add("hidden")
      }
      if (this.hasOverlayTarget) {
        this.overlayTarget.classList.add("hidden")
      }
      this.mobileOpen = false
      this.updateState()
    }
  }

  // Toggle para desktop (collapse/expand)
  toggle() {
    if (this.isMobile) {
      this.toggleMobile()
    } else {
      this.collapsed = !this.collapsed
      localStorage.setItem("sidebarCollapsed", this.collapsed)
      this.updateState()
    }
  }

  // Toggle específico para mobile
  toggleMobile() {
    this.mobileOpen = !this.mobileOpen

    if (this.mobileOpen) {
      this.sidebarTarget.classList.remove("-translate-x-full")
      if (this.hasOverlayTarget) {
        this.overlayTarget.classList.remove("hidden")
      }
      document.body.classList.add("overflow-hidden")
    } else {
      this.sidebarTarget.classList.add("-translate-x-full")
      if (this.hasOverlayTarget) {
        this.overlayTarget.classList.add("hidden")
      }
      document.body.classList.remove("overflow-hidden")
    }
  }

  // Fechar menu ao clicar no overlay
  closeOverlay() {
    if (this.mobileOpen) {
      this.toggleMobile()
    }
  }

  // Fechar menu ao clicar em um link (mobile)
  closeMobileOnNavigate() {
    if (this.isMobile && this.mobileOpen) {
      this.toggleMobile()
    }
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
    if (this.isMobile) return // Não aplicar estado de collapse em mobile

    if (this.collapsed) {
      this.sidebarTarget.classList.remove("w-72")
      this.sidebarTarget.classList.add("w-20")

      this.contentTarget.classList.remove("ml-72", "lg:ml-72")
      this.contentTarget.classList.add("ml-20", "lg:ml-20")

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

      if (this.hasArrowTarget) {
        this.arrowTarget.classList.add("rotate-180")
      }
    } else {
      this.sidebarTarget.classList.remove("w-20")
      this.sidebarTarget.classList.add("w-72")

      this.contentTarget.classList.remove("ml-20", "lg:ml-20")
      this.contentTarget.classList.add("ml-72", "lg:ml-72")

      // Remove hidden primeiro, depois faz fade in
      this.textTargets.forEach(el => {
        el.classList.remove("hidden")
      })

      setTimeout(() => {
        this.textTargets.forEach(el => {
          el.classList.remove("opacity-0")
        })
      }, 100)

      if (this.hasArrowTarget) {
        this.arrowTarget.classList.remove("rotate-180")
      }
    }
  }
}
