import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "arrow", "arrowButton", "sidebar", "content", "link", "overlay", "nav"]

  connect() {
    this.collapsed = localStorage.getItem("sidebarCollapsed") === "true"
    this.mobileOpen = false
    this.checkScreenSize()
    this.updateState(true)
    this.openActiveSubmenu()
    this.restoreScrollPosition()

    // Listener para resize da janela
    this.resizeHandler = this.checkScreenSize.bind(this)
    window.addEventListener('resize', this.resizeHandler)

    // Guarda a posição de rolagem do menu para restaurar na próxima navegação
    if (this.hasNavTarget) {
      this.scrollHandler = () => {
        sessionStorage.setItem("sidebarScrollTop", this.navTarget.scrollTop)
      }
      this.navTarget.addEventListener("scroll", this.scrollHandler)
    }
  }

  disconnect() {
    window.removeEventListener('resize', this.resizeHandler)
    if (this.hasNavTarget && this.scrollHandler) {
      this.navTarget.removeEventListener("scroll", this.scrollHandler)
    }
  }

  // Restaura o scroll do menu (perdido a cada carregamento de página, já que
  // o <nav> é recriado do zero e volta ao topo mesmo estando na mesma seção)
  restoreScrollPosition() {
    if (!this.hasNavTarget) return
    const saved = sessionStorage.getItem("sidebarScrollTop")
    if (saved) {
      this.navTarget.scrollTop = parseInt(saved, 10)
    }
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

      this.setArrowRotation(!this.mobileOpen)
      this.positionArrowButton()
    } else {
      // Em desktop, comportamento normal
      this.sidebarTarget.classList.remove("-translate-x-full")
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

    this.setArrowRotation(!this.mobileOpen)
    this.positionArrowButton()
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

    // Em modo recolhido, o clique expande a sidebar e já abre o submenu clicado
    if (this.collapsed && !this.isMobile) {
      this.collapsed = false
      localStorage.setItem("sidebarCollapsed", this.collapsed)
      this.updateState()
      this.openSubmenuExclusively(submenuId)
      return
    }

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

  // Fecha todos os submenus e abre apenas o indicado (usado ao expandir a sidebar via clique)
  openSubmenuExclusively(submenuId) {
    document.querySelectorAll('[id$="-submenu"]').forEach(el => el.classList.add("hidden"))
    document.querySelectorAll('[data-submenu-id]').forEach(btn => {
      const arrow = btn.querySelector("svg:last-child")
      if (arrow) arrow.classList.remove("rotate-180")
    })

    const submenu = document.getElementById(`${submenuId}-submenu`)
    const button = document.querySelector(`[data-submenu-id="${submenuId}"]`)

    if (submenu) submenu.classList.remove("hidden")
    if (button) {
      const arrow = button.querySelector("svg:last-child")
      if (arrow) arrow.classList.add("rotate-180")
    }
  }

  openActiveSubmenu() {
    // Não abrir submenus se a barra estiver recolhida
    if (this.collapsed && !this.isMobile) return

    document.querySelectorAll('[id$="-submenu"]').forEach(submenu => {
      const activeLink = submenu.querySelector(".bg-white")
      if (activeLink) {
        submenu.classList.remove("hidden")

        const submenuId = submenu.id.replace("-submenu", "")
        const button = document.querySelector(`[data-submenu-id="${submenuId}"]`)
        if (button) {
          const arrow = button.querySelector("svg:last-child")
          if (arrow) {
            arrow.classList.add("rotate-180")
          }
        }
      }
    })
  }

  // Aponta o ícone para a direita (fechado/recolhido) ou esquerda (aberto/expandido)
  setArrowRotation(pointRight) {
    if (!this.hasArrowTarget) return
    this.arrowTarget.classList.toggle("rotate-180", pointRight)
  }

  // Reposiciona o botão de seta (fora do <aside>) para acompanhar a borda da sidebar
  positionArrowButton() {
    if (!this.hasArrowButtonTarget) return

    let left
    if (this.isMobile) {
      left = this.mobileOpen ? "268px" : "16px"
    } else {
      left = this.collapsed ? "60px" : "268px"
    }

    this.arrowButtonTarget.style.left = left
  }

  updateState(immediate = false) {
    if (this.isMobile) return // Não aplicar estado de collapse em mobile

    if (this.collapsed) {
      this.sidebarTarget.classList.remove("w-72")
      this.sidebarTarget.classList.add("w-20")

      this.contentTarget.classList.remove("ml-72", "lg:ml-72")
      this.contentTarget.classList.add("ml-20", "lg:ml-20")

      // Esconde todos os submenus quando recolhido
      document.querySelectorAll('[id$="-submenu"]').forEach(submenu => {
        submenu.classList.add("hidden")
      })

      if (immediate) {
        // Sem delay: evita o "piscar" dos textos ao carregar a página com a sidebar já recolhida
        this.textTargets.forEach(el => {
          el.classList.add("opacity-0", "hidden")
        })
      } else {
        // Adiciona delay antes de esconder os textos (dá tempo da transição de collapse rodar)
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
      }

      this.setArrowRotation(true)
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

      this.setArrowRotation(false)

      // Reabre o submenu ativo ao expandir novamente
      this.openActiveSubmenu()
    }

    this.positionArrowButton()
  }
}
