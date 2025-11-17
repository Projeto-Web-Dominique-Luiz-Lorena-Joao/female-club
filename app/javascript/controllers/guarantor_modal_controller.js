import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "toggleSwitch",
    "guarantorSection",
    "guarantorName",
    "guarantorCpf",
    "guarantorPhone",
    "guarantorRelationship",
    "guarantorAddress",
    "guarantorInfo",
    "guarantorId"
  ]

  connect() {
    console.log("Guarantor modal controller conectado")
    // Verifica se já existe um fiador ao carregar
    if (this.hasGuarantorIdTarget && this.guarantorIdTarget.value) {
      this.showGuarantorInfo()
    }
  }

  toggleGuarantor(event) {
    const hasGuarantor = event.target.checked

    if (hasGuarantor) {
      // Verifica se já existe fiador cadastrado
      if (this.hasGuarantorIdTarget && this.guarantorIdTarget.value) {
        this.showGuarantorInfo()
      } else {
        this.openModal()
      }
    } else {
      this.hideGuarantorInfo()
    }
  }

  openModal() {
    // Limpa o formulário apenas se não estiver editando
    const isEditing = this.guarantorSectionTarget.innerHTML.trim() !== ""
    if (!isEditing) {
      this.clearForm()
    }

    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = "auto"

    // Verifica se tem dados de fiador na seção
    const hasGuarantorData = this.guarantorSectionTarget.innerHTML.trim() !== ""

    // Se não tem fiador, volta o toggle para "não"
    if (!hasGuarantorData) {
      this.toggleSwitchTarget.checked = false
    } else {
      // Garante que o toggle fique marcado se tem fiador
      this.toggleSwitchTarget.checked = true
    }
  }

  saveGuarantor(event) {
    event.preventDefault()

    const guarantorData = {
      full_name: this.guarantorNameTarget.value,
      cpf: this.guarantorCpfTarget.value,
      phone: this.guarantorPhoneTarget.value,
      relationship: this.guarantorRelationshipTarget.value,
      address: this.guarantorAddressTarget.value
    }

    // Validação básica
    if (!guarantorData.full_name || !guarantorData.relationship) {
      alert("Por favor, preencha o nome e o parentesco do fiador.")
      return
    }

    // Exibe as informações do fiador no formulário
    this.displayGuarantorInfo(guarantorData)
    this.closeModal()
  }

  displayGuarantorInfo(data) {
    const infoHTML = `
      <div class="bg-green-50 border border-green-200 rounded-lg p-4">
        <h4 class="font-semibold text-green-800 mb-2">Fiador Cadastrado:</h4>
        <p class="text-sm text-gray-700"><strong>Nome:</strong> ${data.full_name}</p>
        <p class="text-sm text-gray-700"><strong>Parentesco:</strong> ${data.relationship}</p>
        ${data.cpf ? `<p class="text-sm text-gray-700"><strong>CPF:</strong> ${data.cpf}</p>` : ''}
        ${data.phone ? `<p class="text-sm text-gray-700"><strong>Telefone:</strong> ${data.phone}</p>` : ''}
        <input type="hidden" name="guarantor[full_name]" value="${data.full_name}">
        <input type="hidden" name="guarantor[cpf]" value="${data.cpf || ''}">
        <input type="hidden" name="guarantor[phone]" value="${data.phone || ''}">
        <input type="hidden" name="guarantor[relationship]" value="${data.relationship}">
        <input type="hidden" name="guarantor[address]" value="${data.address || ''}">
        <button type="button"
                class="mt-3 text-sm text-blue-600 hover:text-blue-800 underline"
                data-action="click->guarantor-modal#editGuarantor">
          Editar Fiador
        </button>
      </div>
    `

    this.guarantorSectionTarget.innerHTML = infoHTML
    this.guarantorSectionTarget.classList.remove("hidden")

    // Garante que o toggle fique marcado como "Sim"
    this.toggleSwitchTarget.checked = true
  }

  showGuarantorInfo() {
    this.guarantorSectionTarget.classList.remove("hidden")
    this.toggleSwitchTarget.checked = true
  }

  hideGuarantorInfo() {
    this.guarantorSectionTarget.classList.add("hidden")
    this.guarantorSectionTarget.innerHTML = ""

    // Desmarca o toggle quando remove o fiador
    this.toggleSwitchTarget.checked = false
  }

  editGuarantor() {
    // Preenche o modal com os dados atuais
    const hiddenInputs = this.guarantorSectionTarget.querySelectorAll('input[type="hidden"]')
    hiddenInputs.forEach(input => {
      const fieldName = input.name.match(/\[(\w+)\]/)[1]
      const target = this[`guarantor${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)}Target`]
      if (target) {
        target.value = input.value
      }
    })

    this.openModal()
  }

  clearForm() {
    this.guarantorNameTarget.value = ""
    this.guarantorCpfTarget.value = ""
    this.guarantorPhoneTarget.value = ""
    this.guarantorRelationshipTarget.value = ""
    this.guarantorAddressTarget.value = ""
  }
}
