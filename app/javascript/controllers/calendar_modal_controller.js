import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "title", "content"]

  connect() {
    // Carregar dados dos agendamentos
    const dataScript = document.getElementById('appointments-data')
    if (dataScript) {
      try {
        this.appointmentsData = JSON.parse(dataScript.textContent)
      } catch(e) {
        console.error('Erro ao parsear dados:', e)
        this.appointmentsData = {}
      }
    }

    // Guardar referências aos elementos antes de mover
    this.modal = this.modalTarget
    this.title = this.titleTarget
    this.content = this.contentTarget

    // Pegar referência do botão de fechar antes de mover
    this.closeButton = this.modal.querySelector('[data-action="click->calendar-modal#close"]')

    // Mover o modal para o body para evitar problemas com overflow:hidden dos containers pai
    document.body.appendChild(this.modal)

    // Adicionar event listeners diretamente (pois o modal agora está fora do escopo do controller)
    this.boundClose = this.close.bind(this)
    this.boundCloseIfOutside = this.closeIfOutside.bind(this)

    if (this.closeButton) {
      this.closeButton.addEventListener('click', this.boundClose)
    }
    this.modal.addEventListener('click', this.boundCloseIfOutside)

    // Fechar com ESC
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundHandleKeydown)
    if (this.closeButton) {
      this.closeButton.removeEventListener('click', this.boundClose)
    }
    this.modal.removeEventListener('click', this.boundCloseIfOutside)
  }

  handleKeydown(e) {
    if (e.key === 'Escape') {
      this.close()
    }
  }

  open(event) {
    event.preventDefault()
    event.stopPropagation()

    const day = parseInt(event.currentTarget.dataset.day)
    const month = parseInt(event.currentTarget.dataset.month)
    const year = parseInt(event.currentTarget.dataset.year)

    // Formatar data
    const date = new Date(year, month - 1, day)
    const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }
    const dateStr = date.toLocaleDateString('pt-BR', options)

    this.title.textContent = 'Agendamentos - ' + dateStr.charAt(0).toUpperCase() + dateStr.slice(1)

    // Pegar agendamentos do dia
    const appointments = this.appointmentsData[day] || []

    if (appointments.length === 0) {
      this.content.innerHTML = '<p class="text-gray-500 text-center py-8">Nenhum agendamento neste dia.</p>'
    } else {
      let html = '<div class="flex flex-col gap-3 max-h-96 overflow-y-auto">'

      appointments.forEach(appointment => {
        let statusClasses = 'bg-yellow-100 text-yellow-800'
        let statusText = 'Não Compareceu'

        if (appointment.status === 'agendado') {
          statusClasses = 'bg-blue-100 text-blue-800'
          statusText = 'Agendado'
        } else if (appointment.status === 'concluido') {
          statusClasses = 'bg-green-100 text-green-800'
          statusText = 'Concluído'
        } else if (appointment.status === 'cancelado') {
          statusClasses = 'bg-red-100 text-red-800'
          statusText = 'Cancelado'
        }

        const customerName = appointment.customer ? this.escapeHtml(appointment.customer.full_name) : 'N/A'
        const serviceName = appointment.service ? this.escapeHtml(appointment.service.name) : 'N/A'
        const servicePrice = appointment.service && appointment.service.price ? this.formatCurrency(appointment.service.price) : 'N/A'
        const employeeName = appointment.employee ? this.escapeHtml(appointment.employee.full_name) : 'N/A'
        const appointmentTime = this.escapeHtml(appointment.appointment_time)
        const endTime = appointment.end_time ? this.escapeHtml(appointment.end_time) : ''
        const duration = appointment.duration ? this.escapeHtml(appointment.duration) : ''
        const timeRange = endTime ? `${appointmentTime} - ${endTime}` : appointmentTime

        html += `<div class="border border-gray-200 rounded-lg p-4">
          <div class="flex justify-between items-start mb-2">
            <div>
              <span class="text-lg font-bold text-gray-900">${timeRange}</span>
              ${duration ? `<span class="text-sm text-gray-500 ml-2">(${duration})</span>` : ''}
            </div>
            <span class="text-xs px-2 py-1 rounded-full font-medium ${statusClasses}">${this.escapeHtml(statusText)}</span>
          </div>
          <div class="flex flex-col gap-2 ml-2">
            <div class="text-sm text-gray-700"><strong>Cliente:</strong> ${customerName}</div>
            <div class="text-sm text-gray-700"><strong>Serviço:</strong> ${serviceName}</div>
            <div class="text-sm text-gray-700"><strong>Valor:</strong> <span class="text-green-600 font-semibold">${servicePrice}</span></div>
            <div class="text-sm text-gray-700"><strong>Profissional:</strong> ${employeeName}</div>
          </div>
        </div>`
      })

      html += '</div>'
      this.content.innerHTML = html
    }

    this.modal.classList.remove('hidden')
    document.body.classList.add('overflow-hidden')
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.modal.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
  }

  closeIfOutside(event) {
    if (event.target === this.modal) {
      this.close()
    }
  }

  escapeHtml(text) {
    if (text === null || text === undefined) return ''
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  formatCurrency(value) {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(value)
  }
}
