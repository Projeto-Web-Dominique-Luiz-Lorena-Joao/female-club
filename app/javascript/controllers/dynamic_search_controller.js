import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = {
    searchUrl: String,
    itemType: String
  }

  connect() {
    this.searchTimeout = null
    this.selectedIndex = -1
    document.addEventListener("click", this.handleGlobalClick.bind(this))
    this.inputTarget.addEventListener("input", this.performSearch.bind(this))
    this.inputTarget.addEventListener("keydown", this.handleKeydown.bind(this))
    this.inputTarget.addEventListener("focus", this.showResults.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleGlobalClick.bind(this))
  }

  handleGlobalClick(event) {
    if (event.target !== this.inputTarget && !this.resultsTarget.contains(event.target)) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  performSearch() {
    const query = this.inputTarget.value.trim()

    clearTimeout(this.searchTimeout)
    this.selectedIndex = -1

    if (query.length === 0) {
      this.resultsTarget.innerHTML = ""
      this.resultsTarget.classList.add("hidden")
      return
    }

    this.searchTimeout = setTimeout(() => {
      const searchUrl = this.element.getAttribute("data-dynamic-search-search-url")
      const url = `${searchUrl}?query=${encodeURIComponent(query)}`

      console.log("Search URL:", url)

      fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
        .then((response) => {
          if (!response.ok) {
            console.error(`HTTP Error! status: ${response.status}`)
            return response.text().then(text => {
              console.error("Response body:", text.substring(0, 500))
              throw new Error(`HTTP ${response.status}`)
            })
          }
          return response.json()
        })
        .then((data) => this.displayResults(data))
        .catch((error) => console.error("Erro na busca:", error))
    }, 300)
  }

  displayResults(items) {
    this.resultsTarget.innerHTML = ""

    if (items.length === 0) {
      const noResults = document.createElement("div")
      noResults.className = "px-3 py-2 text-gray-500 italic"
      noResults.textContent = "Nenhum resultado encontrado"
      this.resultsTarget.appendChild(noResults)
    } else {
      items.forEach((item) => {
        const div = document.createElement("div")
        div.className = "px-3 py-2 cursor-pointer hover:bg-gray-100 border-b border-gray-100 last:border-b-0 transition-colors"

        const nameSpan = document.createElement("div")
        nameSpan.className = "font-medium text-gray-900"
        nameSpan.textContent = item.name
        div.appendChild(nameSpan)

        if (item.subtitle) {
          const subtitleSpan = document.createElement("div")
          subtitleSpan.className = "text-sm text-gray-500"
          subtitleSpan.textContent = item.subtitle
          div.appendChild(subtitleSpan)
        }

        div.dataset.resultItem = "true"
        div.dataset.id = item.id
        div.dataset.name = item.name
        div.addEventListener("click", () => this.selectItem(item.id, item.name))
        this.resultsTarget.appendChild(div)
      })
    }

    this.resultsTarget.classList.remove("hidden")
  }

  selectItem(id, name) {
    this.inputTarget.value = name
    this.inputTarget.dataset.selectedId = id

    const hiddenInputId = this.inputTarget.id.replace("product_input_", "product_input_").replace(/_id$/, "_id_hidden")
    const hiddenInput = document.getElementById(hiddenInputId)
    if (hiddenInput) {
      hiddenInput.value = id
    }

    const event = new CustomEvent("dynamic-search:selected", {
      detail: { id: id, name: name, itemType: this.itemTypeValue }
    })
    document.dispatchEvent(event)

    this.resultsTarget.classList.add("hidden")
  }

  handleKeydown(event) {
    if (this.resultsTarget.classList.contains("hidden")) {
      return
    }

    const items = this.resultsTarget.querySelectorAll("[data-result-item]")

    if (items.length === 0) {
      return
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.highlightItem(items)
        break

      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.highlightItem(items)
        break

      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          const item = items[this.selectedIndex]
          this.selectItem(item.dataset.id, item.dataset.name)
        }
        break

      case "Escape":
        event.preventDefault()
        this.resultsTarget.classList.add("hidden")
        this.selectedIndex = -1
        break
    }
  }

  highlightItem(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add("bg-green-100", "font-medium")
      } else {
        item.classList.remove("bg-green-100", "font-medium")
      }
    })

    if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
      items[this.selectedIndex].scrollIntoView({ block: "nearest" })
    }
  }

  showResults() {
    const query = this.inputTarget.value.trim()
    if (query.length > 0) {
      this.resultsTarget.classList.remove("hidden")
    }
  }
}
