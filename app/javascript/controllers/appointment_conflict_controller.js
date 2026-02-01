import { Controller } from "@hotwired/stimulus"

// Controller para verificar conflitos de horário em agendamentos
export default class extends Controller {
  static values = {
    checkUrl: { type: String, default: "/service_appointments/check_conflicts" },
    excludeId: String
  }

  connect() {
    this.debounceTimer = null
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  checkConflict() {
    // Debounce para evitar muitas requisições
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    this.debounceTimer = setTimeout(() => {
      this.performCheck()
    }, 300)
  }

  async performCheck() {
    const employeeId = document.getElementById('service_appointment_employee_id')?.value
    const appointmentDate = document.getElementById('appointment_date_field')?.value
    const durationMinutes = document.getElementById('duration_minutes_field')?.value

    // Se não tiver os dados necessários, esconde o alerta
    if (!employeeId || !appointmentDate || !durationMinutes) {
      this.hideConflictAlert()
      return
    }

    try {
      const params = new URLSearchParams({
        employee_id: employeeId,
        start_time: appointmentDate,
        duration_minutes: durationMinutes
      })

      // Adiciona exclude_id se estiver editando
      if (this.excludeIdValue) {
        params.append('exclude_id', this.excludeIdValue)
      }

      const response = await fetch(`${this.checkUrlValue}?${params}`)
      const data = await response.json()

      if (!data.available) {
        this.showConflictAlert(data.message)
      } else {
        this.hideConflictAlert()
      }
    } catch (error) {
      console.error('Erro ao verificar conflito:', error)
      this.hideConflictAlert()
    }
  }

  showConflictAlert(message) {
    const alert = document.getElementById('conflict_alert')
    const messageEl = document.getElementById('conflict_message')

    if (alert && messageEl) {
      messageEl.textContent = message
      alert.classList.remove('hidden')
    }
  }

  hideConflictAlert() {
    const alert = document.getElementById('conflict_alert')
    if (alert) {
      alert.classList.add('hidden')
    }
  }
}
