import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["perPage", "defaultPerPage"]
  static values = {
    updatePath: String
  }

  connect() {
    console.log("Pagination controller connected!")
  }

  changePerPage(event) {
    console.log("changePerPage called with value:", event.target.value)
    const value = event.target.value
    const url = new URL(window.location.href)
    url.searchParams.set('per_page', value)
    url.searchParams.delete('page') // Volta para página 1

    // Navegação direta
    window.location.href = url.toString()
  }

  changeDefault(event) {
    console.log("changeDefault called with value:", event.target.value)
    const value = event.target.value
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.updatePathValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/html'
      },
      body: JSON.stringify({ items_per_page: value || null })
    }).then(() => {
      window.location.reload()
    })
  }
}
