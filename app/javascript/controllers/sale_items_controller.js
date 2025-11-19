import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "results"]
  static values = {
    itemType: String,
    searchUrl: String
  }

  connect() {
    try {
      console.log(`[SALE ITEMS] ✓ CONTROLLER CONNECTED for itemType: ${this.itemTypeValue}`)
    console.log(`[SALE ITEMS] this.element:`, this.element)
    console.log(`[SALE ITEMS] searchInputTarget:`, this.searchInputTarget)
    console.log(`[SALE ITEMS] resultsTarget:`, this.resultsTarget)

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
    } catch (e) {
      console.error(`[SALE ITEMS] ❌ Error in connect:`, e)
    }
  }

  attachQuantityListeners() {
    const quantityInputs = this.element.querySelectorAll('.quantity-input')
    quantityInputs.forEach(input => {
      input.addEventListener('input', () => {
        this.updateRowTotal(input)
        this.updateGrandTotal()
      })
      input.addEventListener('change', () => {
        this.updateRowTotal(input)
        this.updateGrandTotal()
      })
    })
  }

  updateRowTotal(quantityInput) {
    const row = quantityInput.closest('tr')
    if (!row) return

    const quantity = parseInt(quantityInput.value) || 0
    const unitPriceField = row.querySelector('input[name*="[unit_price]"]')
    if (!unitPriceField) return

    const unitPrice = parseFloat(unitPriceField.value) || 0
    const total = quantity * unitPrice

    // Update the total span in the row
    const totalSpan = row.querySelector('td:nth-child(4) span')
    if (totalSpan) {
      totalSpan.textContent = this.formatPrice(total)
    }
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
    console.log(`[SALE ITEMS] ✓ Item selected:`, item)
    console.log(`[SALE ITEMS] Setting selectedItem from null to:`, item)
    this.selectedItem = item
    console.log(`[SALE ITEMS] ✓ selectedItem is now set:`, this.selectedItem)
    console.log(`[SALE ITEMS] Setting searchInputTarget value to:`, item.name)
    this.searchInputTarget.value = item.name
    console.log(`[SALE ITEMS] Hiding results`)
    this.resultsTarget.classList.add("hidden")
    console.log(`[SALE ITEMS] ✓ selectItem complete. selectedItem:`, this.selectedItem, `searchInput value:`, this.searchInputTarget.value)
  }

  addItem(event) {
    console.log(`[SALE ITEMS] ==========================================`)
    console.log(`[SALE ITEMS] 🔴 addItem clicked!`)
    console.log(`[SALE ITEMS] event:`, event)
    console.log(`[SALE ITEMS] event.target:`, event.target)
    console.log(`[SALE ITEMS] this:`, this)
    event.preventDefault()

    console.log(`[SALE ITEMS] ✓ preventDefault called`)
    console.log(`[SALE ITEMS] selectedItem:`, this.selectedItem)
    if (!this.selectedItem) {
      const itemTypeName = this.itemTypeValue === 'product' ? 'produto' : 'serviço'
      console.error(`[SALE ITEMS] ❌ No item selected, showing alert for ${itemTypeName}`)
      alert(`Por favor, selecione um ${itemTypeName} primeiro`)
      return
    }
    console.log(`[SALE ITEMS] ✓ Item is selected, proceeding to add`)

    // Check if item already exists in the table
    const itemType = this.itemTypeValue
    const fieldId = itemType === "product" ? 'product_id' : 'service_id'
    const tableBodyId = `${itemType === 'product' ? 'products' : 'services'}_table_body`
    console.log(`[SALE ITEMS] Looking for tableBodyId: ${tableBodyId}`)
    const tableBody = document.getElementById(tableBodyId)

    if (tableBody) {
      const rows = Array.from(tableBody.querySelectorAll('tr'))
      console.log(`[SALE ITEMS] ✓ Found ${rows.length} rows, checking for duplicate ${fieldId}=${this.selectedItem.id}`)

      const existingRow = rows.find(row => {
        if (row.style.display === 'none') return false
        const fieldInput = row.querySelector(`input[name*="[${fieldId}]"]`)
        if (!fieldInput) return false
        const matches = fieldInput.value === String(this.selectedItem.id)
        if (matches) {
          console.log(`[SALE ITEMS] ✓ Found duplicate: ${fieldId}=${fieldInput.value}`)
        }
        return matches
      })

      if (existingRow) {
        console.log(`[SALE ITEMS] Item already exists, increasing quantity`)
        // Item already exists - increase quantity instead
        const quantityInput = existingRow.querySelector('.quantity-input')
        if (quantityInput) {
          const currentQty = parseInt(quantityInput.value) || 0
          console.log(`[SALE ITEMS] Increasing quantity from ${currentQty} to ${currentQty + 1}`)
          quantityInput.value = currentQty + 1
          quantityInput.dispatchEvent(new Event('change', { bubbles: true }))
          alert('Este item já existe na venda. A quantidade foi aumentada.')
        }
        this.searchInputTarget.value = ""
        this.selectedItem = null
        return
      }
    } else {
      console.warn(`[SALE ITEMS] ⚠️ tableBody not found yet (might be okay if table doesn't exist)`)
    }

    console.log(`[SALE ITEMS] ✓ About to add NEW item to table:`, this.selectedItem)
    this.addItemToTable(this.selectedItem)
    console.log(`[SALE ITEMS] ✓ addItemToTable returned`)
    this.searchInputTarget.value = ""
    this.selectedItem = null

    // Garantir que o total seja atualizado
    setTimeout(() => {
      console.log(`[SALE ITEMS] Updating grand total after timeout`)
      this.updateGrandTotal()
    }, 50)
    console.log(`[SALE ITEMS] ==========================================`)
  }

  addItemToTable(item) {
    if (!item) {
      console.error(`[SALE ITEMS] addItemToTable called with no item!`)
      return
    }

    console.log(`[SALE ITEMS] addItemToTable called with item:`, item)
    const itemType = this.itemTypeValue
    console.log(`[SALE ITEMS] itemType: ${itemType}`)
    const isProduct = itemType === "product"
    const tableBodyId = `${isProduct ? 'products' : 'services'}_table_body`
    console.log(`[SALE ITEMS] Looking for table body with ID: ${tableBodyId}`)
    const tableBody = document.getElementById(tableBodyId)

    if (!tableBody) {
      console.error(`[SALE ITEMS] ❌ Table body NOT found: ${tableBodyId}`)
      console.error(`[SALE ITEMS] Available elements with table_body in ID:`, document.querySelectorAll('[id*="table_body"]'))
      console.error(`[SALE ITEMS] this.element:`, this.element)
      console.error(`[SALE ITEMS] All tables in DOM:`, document.querySelectorAll('table'))
      return
    }

    console.log(`[SALE ITEMS] ✓ Table body found! Adding new item`)
    const fieldId = isProduct ? 'product_id' : 'service_id'
    console.log(`[SALE ITEMS] Adding new item: ${fieldId}=${item.id}, name="${item.name}"`)

    // Remove mensagem vazia se existir (procura em todo o elemento container)
    const table = tableBody.closest('table')
    if (table) {
      const emptyMessage = table.parentElement.querySelector('p.italic')
      if (emptyMessage) {
        console.log(`[SALE ITEMS] Removing empty message`)
        emptyMessage.remove()
      }
    }

    // Calcular o novo índice baseado nas linhas existentes
    const currentRows = tableBody.querySelectorAll('tr').length
    const fieldPrefix = isProduct ? 'sale_products_attributes' : 'sale_services_attributes'
    const itemIdField = isProduct ? 'product_id' : 'service_id'

    // Criar nova linha
    const tr = document.createElement('tr')
    tr.id = `${itemType}_row_${currentRows}`
    tr.className = 'border-b hover:bg-gray-50'

    const price = parseFloat(item.price) || 0

    console.log(`[SALE ITEMS] Creating row with index ${currentRows}, fieldPrefix: ${fieldPrefix}, itemIdField: ${itemIdField}`)

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
               name="sale[${fieldPrefix}][${currentRows}][${itemIdField}]"
               value="${item.id}">
        <input type="hidden"
               name="sale[${fieldPrefix}][${currentRows}][unit_price]"
               value="${price}">
        <input type="hidden"
               name="sale[${fieldPrefix}][${currentRows}][_destroy]"
               value="0"
               class="destroy_checkbox">
        <button type="button"
                class="text-red-600 hover:text-red-800 font-bold"
                onclick="removeRow('${itemType}', ${currentRows})">
          ✕
        </button>
      </td>
    `

    console.log(`[SALE ITEMS] About to append row to tableBody. TR HTML:`, tr.outerHTML)
    tableBody.appendChild(tr)
    console.log(`[SALE ITEMS] ✓ Row successfully appended to table! Table body now has ${tableBody.querySelectorAll('tr').length} rows`)
    console.log(`[SALE ITEMS] Row element in DOM:`, document.getElementById(`${itemType}_row_${currentRows}`))

    // Adicionar listener para atualizar total quando mudar quantidade (em tempo real)
    const quantityInput = tr.querySelector('.quantity-input')
    if (quantityInput) {
      console.log(`[SALE ITEMS] ✓ Found quantity input, adding change listeners`)
      const self = this
      quantityInput.addEventListener('input', function() {
        console.log(`[SALE ITEMS] Quantity input changed`)
        self.updateTotal(itemType, currentRows, price)
        self.updateGrandTotal()
      })
      quantityInput.addEventListener('change', function() {
        console.log(`[SALE ITEMS] Quantity input changed (change event)`)
        self.updateTotal(itemType, currentRows, price)
        self.updateGrandTotal()
      })
    } else {
      console.error(`[SALE ITEMS] ❌ Could not find quantity input in row!`)
    }
  }

  updateGrandTotal() {
    // Calcular total de produtos
    let productsTotal = 0
    const productRows = document.querySelectorAll('#products_table_body tr')
    productRows.forEach(row => {
      if (row.style.display === 'none') return

      const destroyCheckbox = row.querySelector('.destroy_checkbox')
      if (destroyCheckbox && destroyCheckbox.value === '1') return

      const quantityInput = row.querySelector('.quantity-input')
      const unitPriceInput = row.querySelector('[name*="[unit_price]"]')
      if (quantityInput && unitPriceInput) {
        const quantity = parseInt(quantityInput.value) || 0
        const unitPrice = parseFloat(unitPriceInput.value) || 0
        productsTotal += quantity * unitPrice
      }
    })

    // Calcular total de serviços
    let servicesTotal = 0
    const serviceRows = document.querySelectorAll('#services_table_body tr')
    serviceRows.forEach(row => {
      if (row.style.display === 'none') return

      const destroyCheckbox = row.querySelector('.destroy_checkbox')
      if (destroyCheckbox && destroyCheckbox.value === '1') return

      const quantityInput = row.querySelector('.quantity-input')
      const unitPriceInput = row.querySelector('[name*="[unit_price]"]')
      if (quantityInput && unitPriceInput) {
        const quantity = parseInt(quantityInput.value) || 0
        const unitPrice = parseFloat(unitPriceInput.value) || 0
        servicesTotal += quantity * unitPrice
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
    destroyCheckbox.value = '1'
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
      if (destroyCheckbox && destroyCheckbox.value === '1') {
        return
      }

      const quantityInput = row.querySelector('.quantity-input')
      const unitPriceInput = row.querySelector('[name*="[unit_price]"]')
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
    if (row.style.display !== 'none') {
      const destroyCheckbox = row.querySelector('.destroy_checkbox')
      if (destroyCheckbox && destroyCheckbox.value === '1') {
        return
      }

      const quantityInput = row.querySelector('.quantity-input')
      const unitPriceInput = row.querySelector('[name*="[unit_price]"]')
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
