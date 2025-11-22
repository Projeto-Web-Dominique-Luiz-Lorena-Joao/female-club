import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "section", "toggle", "input", "statusText" ]

  connect() {
    if (this.toggleTarget.checked) {
      this.sectionTarget.classList.remove("hidden")
    }
    this.updateText()
  }

  toggleSection() {
    if (this.toggleTarget.checked) {
      this.show()
    } else {
      this.hide()
    }
    this.updateText()
  }

  show() {
    this.sectionTarget.classList.remove("hidden")
    this.sectionTarget.scrollIntoView({ behavior: 'smooth', block: 'center' })
    this.setRequired(true)
  }

  hide() {
    this.sectionTarget.classList.add("hidden")
    this.clearFields()
    this.setRequired(false)
  }

  clearFields() {
    this.inputTargets.forEach(input => {
      input.value = ""
    })
  }
  
  setRequired(isRequired) {
    const mandatoryFields = this.inputTargets.filter(input => 
      input.name.includes('[full_name]') || input.name.includes('[relationship]')
    )
    
    mandatoryFields.forEach(field => {
      field.required = isRequired
    })
  }
}