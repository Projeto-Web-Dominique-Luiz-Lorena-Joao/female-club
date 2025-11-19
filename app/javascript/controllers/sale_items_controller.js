import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "results"]
  static values = {
    itemType: String,
    searchUrl: String
  }

  connect() {
    this.searchTimeout = null
    this.selectedIndex = -1
    this.selectedItem = null
    this.handleGlobalClick = this.handleGlobalClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("click", this.handleGlobalClick)
    this.searchInputTarget.addEventListener("keydown", this.handleKeydown)

    // Adicionar listeners para campos de quantidade já existentes
    this.attachQuantityListeners()

    // Inicializar o total se houver itens
    setTimeout(() => {
      this.updateGrandTotal()
    }, 100)
  }

  attachQuantityListeners() {
    const quantityInputs = this.element.querySelectorAll('.quantity-input')
    quantityInputs.forEach(input => {
      input.addEventListener('input', () => {
        this.updateGrandTotal()
      })
      input.addEventListener('change', () => {
        this.updateGrandTotal()
      })
    })
  }

  disconnect() {
    document.removeEventListener("click", this.handleGlobalClick)
    this.searchInputTarget.removeEventListener("keydown", this.handleKeydown)
  }

  handleGlobalClick(event) {
    // Só fecha se clicar fora do container do autocomplete
    const isClickInside = this.element.contains(event.target)
    if (!isClickInside) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  search() {
    const query = this.searchInputTarget.value.trim()

    clearTimeout(this.searchTimeout)
    this.selectedIndex = -1

    if (query.length === 0) {
      this.resultsTarget.classList.add("hidden")
      return
    }

    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  performSearch(query) {
    fetch(`${this.searchUrlValue}?query=${encodeURIComponent(query)}`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => this.displayResults(data))
      .catch(error => {
        console.error("Erro na busca:", error)
        this.resultsTarget.innerHTML = '<div class="px-3 py-2 text-red-500">Erro ao buscar</div>'
        this.resultsTarget.classList.remove("hidden")
      })
  }

  focus() {
    const query = this.searchInputTarget.value.trim()
    if (query.length > 0) {
      this.resultsTarget.classList.remove("hidden")
    }
  }

  displayResults(items) {
    this.resultsTarget.innerHTML = ""

    if (items.length === 0) {
      const noResults = document.createElement("div")
      noResults.className = "px-3 py-2 text-gray-500 italic"
      noResults.textContent = "Nenhum resultado encontrado"
      this.resultsTarget.appendChild(noResults)
    } else {
      items.forEach(item => {
        const div = document.createElement("div")
        div.className = "px-3 py-2 cursor-pointer hover:bg-gray-100 border-b border-gray-100 last:border-b-0 transition-colors"
        div.textContent = `${item.name} - R$ ${this.formatPrice(item.price)}`
        div.dataset.resultItem = "true"
        div.dataset.itemId = item.id
        div.dataset.itemName = item.name
        div.dataset.itemPrice = item.price
        div.addEventListener("click", () => this.selectItem(item))
        this.resultsTarget.appendChild(div)
      })
    }

    this.resultsTarget.classList.remove("hidden")
  }

  formatPrice(price) {
    return (price || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
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
          const item = items[this.selectedIndex]
          this.selectItem({
            id: parseInt(item.dataset.itemId),
            name: item.dataset.itemName,
            price: parseFloat(item.dataset.itemPrice)
          })
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
        item.classList.add("bg-blue-100", "font-medium")
      } else {
        item.classList.remove("bg-blue-100", "font-medium")
      }
    })

    if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
      items[this.selectedIndex].scrollIntoView({ block: "nearest" })
    }
  }

  selectItem(item) {
    this.selectedItem = item
    this.searchInputTarget.value = item.name
    this.resultsTarget.classList.add("hidden")
  }

  addItem(event) {
    event.preventDefault()

    if (!this.selectedItem) {
      const itemTypeName = this.itemTypeValue === 'product' ? 'produto' : 'serviço'
      alert(`Por favor, selecione um ${itemTypeName} primeiro`)
      return
    }

    this.addItemToTable(this.selectedItem)
    this.searchInputTarget.value = ""
    this.selectedItem = null

    // Garantir que o total seja atualizado
    setTimeout(() => {
      this.updateGrandTotal()
    }, 50)
  }

  addItemToTable(item) {
    const itemType = this.itemTypeValue
    const isProduct = itemType === "product"
    const tableBodyId = `${isProduct ? 'products' : 'services'}_table_body`
    const tableBody = document.getElementById(tableBodyId)

    if (!tableBody) {
      return
    }

    // Remove mensagem vazia se existir (procura em todo o elemento container)
    const table = tableBody.closest('table')
    if (table) {
      const emptyMessage = table.parentElement.querySelector('p.italic')
      if (emptyMessage) {
        emptyMessage.remove()
      }
    }

    // Calcular o novo índice baseado nas linhas existentes
    const currentRows = tableBody.querySelectorAll('tr').length
    const fieldPrefix = isProduct ? 'sale_products_attributes' : 'sale_services_attributes'
    const fieldId = isProduct ? 'product_id' : 'service_id'

    // Criar nova linha
    const tr = document.createElement('tr')
    tr.id = `${itemType}_row_${currentRows}`
    tr.className = 'border-b hover:bg-gray-50'

    const price = parseFloat(item.price) || 0

    tr.innerHTML = `
      <td class="px-3 py-2">${item.name}</td>
      <td class="text-center px-3 py-2">
        <input type="number"
               min="1"
               value="1"
               name="sale[${fieldPrefix}][${currentRows}][quantity]"
               class="w-16 text-center px-2 py-1 border border-gray-300 rounded quantity-input"
               data-item-type="${itemType}"
               data-row-index="${currentRows}">
      </td>
      <td class="text-right px-3 py-2">R$ ${this.formatPrice(price)}</td>
      <td class="text-right px-3 py-2 font-semibold">
        R$ <span class="${itemType}_total_${currentRows}">${this.formatPrice(price)}</span>
      </td>
      <td class="text-center px-3 py-2">
        <input type="hidden"
               name="sale[${fieldPrefix}][${currentRows}][${fieldId}]"
               value="${item.id}">
        <input type="hidden"
               name="sale[${fieldPrefix}][${currentRows}][unit_price]"
               value="${price}">
        <input type="hidden"
               name="sale[${fieldPrefix}][${currentRows}][_destroy]"
               value="false"
               class="destroy_checkbox">
        <button type="button"
                class="text-red-600 hover:text-red-800 font-bold"
                onclick="removeRow('${itemType}', ${currentRows})">
          ✕
        </button>
      </td>
    `

    tableBody.appendChild(tr)

    // Adicionar listener para atualizar total quando mudar quantidade (em tempo real)
    const quantityInput = tr.querySelector('.quantity-input')
    if (quantityInput) {
      quantityInput.addEventListener('input', () => {
        this.updateTotal(itemType, currentRows, price)
        this.updateGrandTotal()
      })
      quantityInput.addEventListener('change', () => {
        this.updateTotal(itemType, currentRows, price)
        this.updateGrandTotal()
      })
    }
  }

  updateGrandTotal() {
    // Calcular total de produtos
    let productsTotal = 0
    const productRows = document.querySelectorAll('#products_table_body tr')
    productRows.forEach(row => {
      const destroyCheckbox = row.querySelector('.destroy_checkbox')
      if (!destroyCheckbox || destroyCheckbox.value !== 'true') {
        const quantityInput = row.querySelector('.quantity-input')
        const unitPriceInput = row.querySelector('[name$="[unit_price]"]')
        if (quantityInput && unitPriceInput) {
          const quantity = parseInt(quantityInput.value) || 0
          const unitPrice = parseFloat(unitPriceInput.value) || 0
          productsTotal += quantity * unitPrice
        }
      }
    })

    // Calcular total de serviços
    let servicesTotal = 0
    const serviceRows = document.querySelectorAll('#services_table_body tr')
    serviceRows.forEach(row => {
      const destroyCheckbox = row.querySelector('.destroy_checkbox')
      if (!destroyCheckbox || destroyCheckbox.value !== 'true') {
        const quantityInput = row.querySelector('.quantity-input')
        const unitPriceInput = row.querySelector('[name$="[unit_price]"]')
        if (quantityInput && unitPriceInput) {
          const quantity = parseInt(quantityInput.value) || 0
          const unitPrice = parseFloat(unitPriceInput.value) || 0
          servicesTotal += quantity * unitPrice
        }
      }
    })

    // Atualizar o campo de valor total
    const totalAmountInput = document.querySelector('input[name="sale[total_amount]"]')
    if (totalAmountInput) {
      const grandTotal = productsTotal + servicesTotal
      totalAmountInput.value = grandTotal.toFixed(2)
    }
  }

  updateTotal(itemType, rowIndex, unitPrice) {
    const row = document.getElementById(`${itemType}_row_${rowIndex}`)
    if (!row) return

    const quantityInput = row.querySelector('.quantity-input')
    if (!quantityInput) return

    const quantity = parseInt(quantityInput.value) || 1
    const total = quantity * unitPrice

    const totalSpan = row.querySelector(`.${itemType}_total_${rowIndex}`)
    if (totalSpan) {
      totalSpan.textContent = this.formatPrice(total)
    }
  }
}

// Funções globais para gerenciar linhas
window.removeRow = function(itemType, rowIndex) {
  const row = document.getElementById(`${itemType}_row_${rowIndex}`)
  if (!row) return

  const destroyCheckbox = row.querySelector('.destroy_checkbox')
  if (destroyCheckbox) {
    destroyCheckbox.value = "true"
  }

  row.style.display = 'none'

  // Recalcular o total
  updateGrandTotalGlobal()
}

// Função global para atualizar o total geral
window.updateGrandTotalGlobal = function() {
  // Calcular total de produtos
  let productsTotal = 0
  const productRows = document.querySelectorAll('#products_table_body tr')
  productRows.forEach(row => {
    if (row.style.display !== 'none') {
      const destroyCheckbox = row.querySelector('.destroy_checkbox')
      if (!destroyCheckbox || destroyCheckbox.value !== 'true') {
        const quantityInput = row.querySelector('.quantity-input')
        const unitPriceInput = row.querySelector('[name$="[unit_price]"]')
        if (quantityInput && unitPriceInput) {
          const quantity = parseInt(quantityInput.value) || 0
          const unitPrice = parseFloat(unitPriceInput.value) || 0
          productsTotal += quantity * unitPrice
        }
      }
    }
  })

  // Calcular total de serviços
  let servicesTotal = 0
  const serviceRows = document.querySelectorAll('#services_table_body tr')
  serviceRows.forEach(row => {
    if (row.style.display !== 'none') {
      const destroyCheckbox = row.querySelector('.destroy_checkbox')
      if (!destroyCheckbox || destroyCheckbox.value !== 'true') {
        const quantityInput = row.querySelector('.quantity-input')
        const unitPriceInput = row.querySelector('[name$="[unit_price]"]')
        if (quantityInput && unitPriceInput) {
          const quantity = parseInt(quantityInput.value) || 0
          const unitPrice = parseFloat(unitPriceInput.value) || 0
          servicesTotal += quantity * unitPrice
        }
      }
    }
  })

  // Atualizar o campo de valor total
  const totalAmountInput = document.querySelector('input[name="sale[total_amount]"]')
  if (totalAmountInput) {
    const grandTotal = productsTotal + servicesTotal
    totalAmountInput.value = grandTotal.toFixed(2)
  }
}
