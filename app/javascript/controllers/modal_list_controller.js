import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupModalListeners()
  }

  setupModalListeners() {
    const productsBtn = document.getElementById("open-products-modal")
    const suppliersBtn = document.getElementById("open-suppliers-modal")
    const productsModal = document.getElementById("products-modal")
    const suppliersModal = document.getElementById("suppliers-modal")
    const closeProductsBtn = document.getElementById("close-products-modal")
    const closeSuppliersBtn = document.getElementById("close-suppliers-modal")

    if (productsBtn) {
      productsBtn.addEventListener("click", () => this.loadAndShowProductsModal(productsModal))
    }

    if (suppliersBtn) {
      suppliersBtn.addEventListener("click", () => this.loadAndShowSuppliersModal(suppliersModal))
    }

    if (closeProductsBtn) {
      closeProductsBtn.addEventListener("click", () => this.closeModal(productsModal))
    }

    if (closeSuppliersBtn) {
      closeSuppliersBtn.addEventListener("click", () => this.closeModal(suppliersModal))
    }

    // Fechar ao clicar no backdrop
    if (productsModal) {
      productsModal.addEventListener("click", (e) => {
        if (e.target === productsModal) {
          this.closeModal(productsModal)
        }
      })
    }

    if (suppliersModal) {
      suppliersModal.addEventListener("click", (e) => {
        if (e.target === suppliersModal) {
          this.closeModal(suppliersModal)
        }
      })
    }
  }

  loadAndShowProductsModal(modal) {
    if (!modal) return

    const modalBody = document.getElementById("products-modal-body")
    modalBody.innerHTML = '<div style="padding: 2rem; text-align: center; color: #6b7280;">Carregando produtos...</div>'

    modal.style.display = "flex"

    fetch("/product_inputs/list_products", {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.json()
      })
      .then((products) => this.renderProductsTable(products, modalBody))
      .catch((error) => {
        console.error("Erro ao carregar produtos:", error)
        modalBody.innerHTML = '<div style="padding: 2rem; text-align: center; color: #ef4444;">Erro ao carregar produtos. Tente novamente.</div>'
      })
  }

  loadAndShowSuppliersModal(modal) {
    if (!modal) return

    const modalBody = document.getElementById("suppliers-modal-body")
    modalBody.innerHTML = '<div style="padding: 2rem; text-align: center; color: #6b7280;">Carregando fornecedores...</div>'

    modal.style.display = "flex"

    fetch("/product_inputs/list_suppliers", {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.json()
      })
      .then((suppliers) => this.renderSuppliersTable(suppliers, modalBody))
      .catch((error) => {
        console.error("Erro ao carregar fornecedores:", error)
        modalBody.innerHTML = '<div style="padding: 2rem; text-align: center; color: #ef4444;">Erro ao carregar fornecedores. Tente novamente.</div>'
      })
  }

  renderProductsTable(products, container) {
    if (products.length === 0) {
      container.innerHTML = '<div class="p-8 text-center text-gray-500">Nenhum produto disponível</div>'
      return
    }

    const html = `
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nome</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Código</th>
            <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase">Estoque</th>
            <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase">Ação</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          ${products.map(product => `
            <tr class="hover:bg-gray-50">
              <td class="px-6 py-4 text-sm text-gray-900">${product.name}</td>
              <td class="px-6 py-4 text-sm text-gray-500">-</td>
              <td class="px-6 py-4 text-center text-sm text-gray-900">${product.subtitle}</td>
              <td class="px-6 py-4 text-center">
                <button type="button" class="select-product-btn bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded text-sm font-medium" data-product-id="${product.id}" data-product-name="${product.name}">
                  Selecionar
                </button>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `

    container.innerHTML = html

    // Adicionar listeners aos botões de seleção
    container.querySelectorAll(".select-product-btn").forEach((btn) => {
      btn.addEventListener("click", () => this.selectProduct(btn))
    })
  }

  renderSuppliersTable(suppliers, container) {
    if (suppliers.length === 0) {
      container.innerHTML = '<div class="p-8 text-center text-gray-500">Nenhum fornecedor disponível</div>'
      return
    }

    const html = `
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nome</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
            <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase">Ação</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          ${suppliers.map(supplier => `
            <tr class="hover:bg-gray-50">
              <td class="px-6 py-4 text-sm text-gray-900">${supplier.name}</td>
              <td class="px-6 py-4 text-sm text-gray-500">Ativo</td>
              <td class="px-6 py-4 text-center">
                <button type="button" class="select-supplier-btn bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-sm font-medium" data-supplier-id="${supplier.id}" data-supplier-name="${supplier.name}">
                  Selecionar
                </button>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `

    container.innerHTML = html

    // Adicionar listeners aos botões de seleção
    container.querySelectorAll(".select-supplier-btn").forEach((btn) => {
      btn.addEventListener("click", () => this.selectSupplier(btn))
    })
  }

  selectProduct(btn) {
    const productId = btn.getAttribute("data-product-id")
    const productName = btn.getAttribute("data-product-name")

    // Preencher o campo e o ID oculto
    document.getElementById("product_input_product_id").value = productName
    document.getElementById("product_input_product_id_hidden").value = productId

    // Disparar evento customizado
    const event = new CustomEvent("dynamic-search:selected", {
      detail: { id: productId, name: productName, itemType: "product" }
    })
    document.dispatchEvent(event)

    // Fechar modal
    const modal = document.getElementById("products-modal")
    this.closeModal(modal)
  }

  selectSupplier(btn) {
    const supplierId = btn.getAttribute("data-supplier-id")
    const supplierName = btn.getAttribute("data-supplier-name")

    // Preencher o campo e o ID oculto
    document.getElementById("product_input_supplier_id").value = supplierName
    document.getElementById("product_input_supplier_id_hidden").value = supplierId

    // Disparar evento customizado
    const event = new CustomEvent("dynamic-search:selected", {
      detail: { id: supplierId, name: supplierName, itemType: "supplier" }
    })
    document.dispatchEvent(event)

    // Fechar modal
    const modal = document.getElementById("suppliers-modal")
    this.closeModal(modal)
  }

  closeModal(modal) {
    if (modal) {
      modal.style.display = "none"
    }
  }
}
