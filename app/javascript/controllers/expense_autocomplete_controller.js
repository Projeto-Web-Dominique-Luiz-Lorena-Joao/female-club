import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "results", "hiddenInput"]
  static values = { searchUrl: String }

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
    this.selectedIndex = -1
    this.searchInputTarget.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    this.searchInputTarget.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.resultsTarget.classList.add("hidden")
      this.selectedIndex = -1
    }
  }

  search() {
    const query = this.searchInputTarget.value.trim()

    if (query.length < 2) {
      this.resultsTarget.classList.add("hidden")
      this.resultsTarget.innerHTML = ""
      this.selectedIndex = -1
      return
    }

    const url = `${this.searchUrlValue}?q=${encodeURIComponent(query)}`

    fetch(url)
      .then(response => response.json())
      .then(data => {
        if (data.length === 0) {
          this.resultsTarget.innerHTML = '<div class="px-4 py-2 text-sm text-gray-500">Nenhum resultado encontrado</div>'
          this.resultsTarget.classList.remove("hidden")
          this.selectedIndex = -1
          return
        }

        this.resultsTarget.innerHTML = data.map(item => `
          <div class="px-4 py-2 hover:bg-gray-100 cursor-pointer transition-colors"
               data-action="click->expense-autocomplete#select"
               data-id="${item.id}"
               data-name="${item.name}"
               data-result-item>
            ${item.name}
          </div>
        `).join("")

        this.resultsTarget.classList.remove("hidden")
        this.selectedIndex = -1
      })
      .catch((error) => {
        console.error("Erro na busca:", error)
        this.resultsTarget.innerHTML = '<div class="px-4 py-2 text-sm text-red-500">Erro ao buscar dados</div>'
        this.resultsTarget.classList.remove("hidden")
      })
  }

  focus() {
    if (this.searchInputTarget.value.trim().length >= 2) {
      this.search()
    }
  }

  select(event) {
    const id = event.currentTarget.dataset.id
    const name = event.currentTarget.dataset.name

    this.hiddenInputTarget.value = id
    this.searchInputTarget.value = name
    this.resultsTarget.classList.add("hidden")
    this.selectedIndex = -1
  }

  clear() {
    this.hiddenInputTarget.value = ""
    this.searchInputTarget.value = ""
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
  }

  handleKeydown(event) {
    if (this.resultsTarget.classList.contains("hidden")) {
      return
    }

    const items = this.resultsTarget.querySelectorAll("[data-result-item]")

    if (items.length === 0) {
      return
    }

    switch(event.key) {
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
          items[this.selectedIndex].click()
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
        item.classList.add("bg-gray-100")
      } else {
        item.classList.remove("bg-gray-100")
      }
    })

    if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
      items[this.selectedIndex].scrollIntoView({ block: "nearest" })
    }
  }
}
