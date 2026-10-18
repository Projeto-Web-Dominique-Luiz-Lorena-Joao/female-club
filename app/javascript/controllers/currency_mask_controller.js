import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('input', (e) => this.formatCurrency(e))
    this.element.addEventListener('blur', (e) => this.formatOnBlur(e))
  }

  formatCurrency(e) {
    let value = e.target.value

    // Remove tudo exceto números
    value = value.replace(/\D/g, '')

    if (value === '') {
      e.target.value = ''
      return
    }

    // Garante que temos pelo menos 3 dígitos (0,01 mínimo)
    while (value.length < 3) {
      value = '0' + value
    }

    // Separa parte inteira e decimal
    let inteira = value.slice(0, -2)
    let decimal = value.slice(-2)

    // Remove zeros à esquerda da parte inteira
    inteira = inteira.replace(/^0+/, '') || '0'

    // Formata a parte inteira com separador de milhar
    inteira = inteira.replace(/\B(?=(\d{3})+(?!\d))/g, '.')

    e.target.value = inteira + ',' + decimal
  }

  formatOnBlur(e) {
    let value = e.target.value

    // Remove tudo exceto números
    value = value.replace(/\D/g, '')

    if (value === '') {
      e.target.value = ''
      return
    }

    // Garante que temos pelo menos 3 dígitos
    while (value.length < 3) {
      value = '0' + value
    }

    // Separa parte inteira e decimal
    let inteira = value.slice(0, -2)
    let decimal = value.slice(-2)

    // Remove zeros à esquerda da parte inteira
    inteira = inteira.replace(/^0+/, '') || '0'

    // Formata a parte inteira com separador de milhar
    inteira = inteira.replace(/\B(?=(\d{3})+(?!\d))/g, '.')

    // Garante sempre 2 casas decimais
    e.target.value = inteira + ',' + decimal
  }
}
