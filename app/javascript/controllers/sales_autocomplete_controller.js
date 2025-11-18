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
    // Abre modal para criar novo cliente
    this.openCreateCustomerModal(name)
    this.resultsTarget.classList.add("hidden")
  }

  openCreateCustomerModal(defaultName) {
    // Cria modal se não existir
    let modal = document.getElementById("createCustomerModal")

    if (!modal) {
      modal = document.createElement("div")
      modal.id = "createCustomerModal"
      modal.className = "fixed inset-0 backdrop-blur-md overflow-y-auto h-full w-full hidden z-50 flex items-center justify-center"
      modal.innerHTML = `
        <div class="relative w-full max-w-md shadow-2xl rounded-lg bg-white my-8">
          <div class="flex justify-between items-center p-6 border-b border-gray-200">
            <h3 class="text-xl font-bold text-gray-800">Novo Cliente</h3>
            <button type="button" class="text-gray-400 hover:text-gray-600 transition" onclick="document.getElementById('createCustomerModal').classList.add('hidden')">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </button>
          </div>

          <form id="createCustomerForm" class="p-6 space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Nome Completo *</label>
              <input type="text"
                     id="customerFullName"
                     name="full_name"
                     class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                     required>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Email <span class="text-xs text-gray-500">(opcional)</span></label>
              <input type="email"
                     id="customerEmail"
                     name="email"
                     class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                     placeholder="exemplo@email.com">
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Telefone <span class="text-xs text-gray-500">(opcional)</span></label>
              <input type="text"
                     id="customerPhone"
                     name="phone"
                     class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                     placeholder="(11) 99999-9999"
                     data-phone-mask="true">
            </div>

            <div class="flex gap-2 mt-8">
              <button type="button"
                      onclick="document.getElementById('createCustomerModal').classList.add('hidden')"
                      class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium transition">
                Cancelar
              </button>
              <button type="button"
                      id="saveCustomerBtn"
                      class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium transition">
                Salvar Cliente
              </button>
            </div>
          </form>
        </div>
      `
      document.body.appendChild(modal)

      // Adiciona listener para salvar
      document.getElementById("saveCustomerBtn").addEventListener("click", (e) => {
        e.preventDefault()
        this.saveNewCustomer()
      })

      // Fecha modal ao clicar fora dele
      modal.addEventListener("click", (e) => {
        if (e.target === modal) {
          modal.classList.add("hidden")
        }
      })

      // Aplica máscara de telefone
      this.applyPhoneMask()
    }

    // Preenche nome padrão
    document.getElementById("customerFullName").value = defaultName
    document.getElementById("customerFullName").focus()
    modal.classList.remove("hidden")
  }

  applyPhoneMask() {
    const phoneInput = document.querySelector('[data-phone-mask="true"]')

    if (phoneInput) {
      phoneInput.addEventListener("input", (e) => {
        let value = e.target.value.replace(/\D/g, "")

        if (value.length > 11) {
          value = value.slice(0, 11)
        }

        if (value.length <= 2) {
          e.target.value = value
        } else if (value.length <= 7) {
          e.target.value = `(${value.slice(0, 2)}) ${value.slice(2)}`
        } else {
          e.target.value = `(${value.slice(0, 2)}) ${value.slice(2, 7)}-${value.slice(7)}`
        }
      })
    }
  }

  saveNewCustomer() {
    const fullName = document.getElementById("customerFullName").value.trim()
    const email = document.getElementById("customerEmail").value.trim()
    const phone = document.getElementById("customerPhone").value.trim()

    if (!fullName) {
      alert("Nome completo é obrigatório")
      return
    }

    if (fullName.length < 3) {
      alert("Nome completo deve ter no mínimo 3 letras")
      return
    }

    // Envia requisição para criar cliente
    fetch("/customers.json", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": this.getCsrfToken()
      },
      body: JSON.stringify({
        customer: {
          full_name: fullName,
          email: email || "",
          phone: phone || ""
        }
      })
    })
    .then(async response => {
      const contentType = response.headers.get("content-type")
      const isJson = contentType && contentType.includes("application/json")

      if (!response.ok) {
        if (isJson) {
          const data = await response.json()
          throw new Error(data.errors ? data.errors.join(", ") : "Erro ao salvar cliente")
        } else {
          const text = await response.text()
          console.error("Resposta não-JSON recebida:", text.substring(0, 500))
          throw new Error("Erro ao salvar cliente. Verifique se você está autenticado.")
        }
      }

      if (isJson) {
        return response.json()
      } else {
        throw new Error("Resposta não é JSON válido")
      }
    })
    .then(data => {
      // Preenche dados no formulário de venda
      this.hiddenInputTarget.value = data.id
      this.searchInputTarget.value = data.full_name
      this.selectedDisplayTarget.textContent = data.full_name

      // Fecha modal
      document.getElementById("createCustomerModal").classList.add("hidden")

      // Limpa formulário
      document.getElementById("createCustomerForm").reset()
    })
    .catch(error => {
      console.error("Erro ao salvar cliente:", error)
      console.error("Stack:", error.stack)
      alert(`Erro ao salvar cliente: ${error.message}`)
    })
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute("content")
  }
}
