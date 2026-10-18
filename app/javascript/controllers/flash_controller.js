import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Flash controller conectado")

    // Auto-fechar após 4 segundos
    this.timeout = setTimeout(() => {
      this.close()
    }, 4000)
  }

  disconnect() {
    // Limpa o timeout se o elemento for removido antes
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  close() {
    // Adiciona animação de fade out
    this.element.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-20px)"

    // Remove o elemento após a animação
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
