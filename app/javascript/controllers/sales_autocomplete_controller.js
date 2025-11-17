import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "hiddenInput", "results", "selectedDisplay"]
  static values = {
    searchUrl: String,
    allowCreate: Boolean
  }

  connect() {
    console.log("Autocomplete controller conectado para:", this.element.id)
    this.searchTimeout = null
    document.addEventListener("click", this.handleGlobalClick.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleGlobalClick.bind(this))
  }

  handleGlobalClick(event) {
    if (event.target !== this.searchInputTarget && !this.resultsTarget.contains(event.target)) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  search(event) {
    const query = this.searchInputTarget.value.trim()

    clearTimeout(this.searchTimeout)

    if (query.length < 2) {
      this.resultsTarget.classList.add("hidden")
      if (!this.allowCreateValue) {
        this.hiddenInputTarget.value = ""
        this.selectedDisplayTarget.textContent = "Nenhum"
      }
      return
    }

    this.searchTimeout = setTimeout(() => {
      fetch(`${this.searchUrlValue}?query=${encodeURIComponent(query)}`)
        .then(response => response.json())
        .then(data => this.displayResults(data, query))
        .catch(error => console.error("Erro na busca:", error))
    }, 300)
  }

  focus(event) {
    const query = this.searchInputTarget.value.trim()
    if (query.length >= 2) {
      this.resultsTarget.classList.remove("hidden")
    }
  }

  closeMenu(event) {
    if (event.target !== this.searchInputTarget && !this.resultsTarget.contains(event.target)) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  displayResults(items, query) {
    this.resultsTarget.innerHTML = ""

    if (items.length === 0) {
      if (this.allowCreateValue) {
        const createDiv = document.createElement("div")
        createDiv.className = "px-3 py-2 cursor-pointer bg-blue-50 hover:bg-blue-100 text-blue-700 font-medium"
        createDiv.textContent = `✓ Criar novo cliente: "${query}"`
        createDiv.addEventListener("click", () => this.selectNewCustomer(query))
        this.resultsTarget.appendChild(createDiv)
      } else {
        const noResults = document.createElement("div")
        noResults.className = "px-3 py-2 text-gray-500 italic"
        noResults.textContent = "Nenhum resultado encontrado"
        this.resultsTarget.appendChild(noResults)
      }
    } else {
      items.forEach(item => {
        const div = document.createElement("div")
        div.className = "px-3 py-2 cursor-pointer hover:bg-gray-100 border-b border-gray-100 last:border-b-0"
        div.textContent = item.name
        div.addEventListener("click", () => this.selectItem(item.id, item.name))
        this.resultsTarget.appendChild(div)
      })

      if (this.allowCreateValue) {
        const createDiv = document.createElement("div")
        createDiv.className = "px-3 py-2 cursor-pointer bg-blue-50 hover:bg-blue-100 text-blue-700 font-medium"
        createDiv.textContent = `✓ Criar novo cliente: "${query}"`
        createDiv.addEventListener("click", () => this.selectNewCustomer(query))
        this.resultsTarget.appendChild(createDiv)
      }
    }

    this.resultsTarget.classList.remove("hidden")
  }

  selectItem(id, name) {
    this.hiddenInputTarget.value = id
    this.searchInputTarget.value = name
    this.selectedDisplayTarget.textContent = name
    this.resultsTarget.classList.add("hidden")
  }

  selectNewCustomer(name) {
    this.hiddenInputTarget.value = ""
    this.searchInputTarget.value = name
    this.selectedDisplayTarget.textContent = `Novo: ${name}`
    this.resultsTarget.classList.add("hidden")
  }
}
