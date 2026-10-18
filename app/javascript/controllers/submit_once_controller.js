import { Controller } from "@hotwired/stimulus"

// Previne submissão dupla de formulários.
// Desabilita o botão de submit após o primeiro clique e mostra feedback visual.
//
// Uso em form_with:
//   form_with(..., data: { controller: "submit-once" })
//
// Uso em button_to:
//   button_to "Ação", path, form: { data: { controller: "submit-once" } }
//
export default class extends Controller {
  connect() {
    this.element.addEventListener("submit", this.handleSubmit.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("submit", this.handleSubmit.bind(this))
  }

  handleSubmit(event) {
    const submitButtons = this.element.querySelectorAll(
      'input[type="submit"], button[type="submit"], button:not([type])'
    )

    submitButtons.forEach((button) => {
      if (button.disabled) {
        event.preventDefault()
        return
      }

      button.disabled = true
      button.dataset.originalText = button.value || button.textContent
      button.classList.add("opacity-50", "cursor-not-allowed")

      if (button.tagName === "INPUT") {
        button.value = "Processando..."
      } else {
        button.textContent = "Processando..."
      }
    })

    // Reabilitar após 8 segundos caso algo dê errado (timeout de segurança)
    setTimeout(() => {
      submitButtons.forEach((button) => {
        button.disabled = false
        button.classList.remove("opacity-50", "cursor-not-allowed")

        if (button.dataset.originalText) {
          if (button.tagName === "INPUT") {
            button.value = button.dataset.originalText
          } else {
            button.textContent = button.dataset.originalText
          }
        }
      })
    }, 8000)
  }
}
