import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Formato: CCCC-TTT-MMM-CCC
  // CCCC = Classe (4 caracteres)
  // TTT = Tipo (3 caracteres)
  // MMM = Marca (3 caracteres)
  // CCC = Cor (3 caracteres)

  connect() {
    this.element.addEventListener('input', (e) => this.formatCode(e))
    this.element.addEventListener('blur', (e) => this.formatOnBlur(e))
  }

  formatCode(e) {
    let value = e.target.value.toUpperCase()

    // Remove tudo exceto letras e números
    value = value.replace(/[^A-Z0-9]/g, '')

    if (value === '') {
      e.target.value = ''
      return
    }

    // Limita a 13 caracteres (4 + 3 + 3 + 3)
    value = value.substring(0, 13)

    // Formata: CCCC-TTT-MMM-CCC
    let formatted = ''
    if (value.length > 0) {
      formatted += value.substring(0, 4)
    }
    if (value.length > 4) {
      formatted += '-' + value.substring(4, 7)
    }
    if (value.length > 7) {
      formatted += '-' + value.substring(7, 10)
    }
    if (value.length > 10) {
      formatted += '-' + value.substring(10, 13)
    }

    e.target.value = formatted
  }

  formatOnBlur(e) {
    let value = e.target.value.toUpperCase()

    // Remove tudo exceto letras e números
    value = value.replace(/[^A-Z0-9]/g, '')

    if (value === '') {
      e.target.value = ''
      return
    }

    // Se chegou aqui, formata corretamente
    value = value.substring(0, 13)

    let formatted = ''
    if (value.length > 0) {
      formatted += value.substring(0, 4)
    }
    if (value.length > 4) {
      formatted += '-' + value.substring(4, 7)
    }
    if (value.length > 7) {
      formatted += '-' + value.substring(7, 10)
    }
    if (value.length > 10) {
      formatted += '-' + value.substring(10, 13)
    }

    e.target.value = formatted
  }
}
