import { Controller } from "@hotwired/stimulus"

// Controller para upload e recorte de imagens
// Usa Cropper.js carregado via CDN
export default class extends Controller {
  static targets = ["input", "preview", "previewContainer", "cropModal", "cropImage", "croppedData", "removeFlag"]
  static values = {
    aspectRatio: { type: Number, default: 1 },
    minWidth: { type: Number, default: 150 },
    minHeight: { type: Number, default: 150 }
  }

  connect() {
    this.cropper = null
    this.originalFile = null
  }

  disconnect() {
    this.destroyCropper()
  }

  // Quando o usuário seleciona um arquivo
  fileSelected(event) {
    const file = event.target.files[0]
    if (!file) return

    // Validar tipo de arquivo
    if (!file.type.startsWith('image/')) {
      alert('Por favor, selecione apenas arquivos de imagem.')
      event.target.value = ''
      return
    }

    // Validar tamanho (máximo 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('A imagem é muito grande. O tamanho máximo é 5MB.')
      event.target.value = ''
      return
    }

    this.originalFile = file

    // Criar URL para preview e abrir modal de crop
    const reader = new FileReader()
    reader.onload = (e) => {
      this.openCropModal(e.target.result)
    }
    reader.readAsDataURL(file)
  }

  openCropModal(imageUrl) {
    // Definir imagem no modal
    this.cropImageTarget.src = imageUrl

    // Mostrar modal
    this.cropModalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'

    // Inicializar Cropper após a imagem carregar
    this.cropImageTarget.onload = () => {
      this.initCropper()
    }
  }

  initCropper() {
    this.destroyCropper()

    // Verificar se Cropper está disponível
    if (typeof Cropper === 'undefined') {
      console.error('Cropper.js não está carregado')
      this.closeCropModal()
      return
    }

    this.cropper = new Cropper(this.cropImageTarget, {
      aspectRatio: this.aspectRatioValue,
      viewMode: 1,
      minCropBoxWidth: this.minWidthValue,
      minCropBoxHeight: this.minHeightValue,
      background: false,
      autoCropArea: 0.8,
      responsive: true,
      restore: false,
      guides: true,
      center: true,
      highlight: true,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false
    })
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  closeCropModal() {
    this.cropModalTarget.classList.add('hidden')
    document.body.style.overflow = ''
    this.destroyCropper()

    // Limpar input se cancelou
    if (this.inputTarget.value && !this.hasCroppedDataTarget) {
      this.inputTarget.value = ''
    }
  }

  // Aplicar o recorte
  applyCrop() {
    if (!this.cropper) return

    // Obter canvas do recorte
    const canvas = this.cropper.getCroppedCanvas({
      width: 400,
      height: 400,
      minWidth: this.minWidthValue,
      minHeight: this.minHeightValue,
      maxWidth: 800,
      maxHeight: 800,
      fillColor: '#fff',
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    if (!canvas) {
      alert('Erro ao processar a imagem. Tente novamente.')
      return
    }

    // Converter para blob e atualizar o input
    canvas.toBlob((blob) => {
      if (!blob) {
        alert('Erro ao processar a imagem. Tente novamente.')
        return
      }

      // Criar novo arquivo com o blob recortado
      const croppedFile = new File([blob], this.originalFile.name, {
        type: 'image/jpeg',
        lastModified: Date.now()
      })

      // Atualizar o input file com o arquivo recortado
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(croppedFile)
      this.inputTarget.files = dataTransfer.files

      // Mostrar preview
      this.showPreview(canvas.toDataURL('image/jpeg', 0.9))

      // Fechar modal
      this.closeCropModal()

      // Limpar flag de remoção se existir
      if (this.hasRemoveFlagTarget) {
        this.removeFlagTarget.checked = false
      }
    }, 'image/jpeg', 0.9)
  }

  showPreview(dataUrl) {
    if (this.hasPreviewTarget) {
      this.previewTarget.src = dataUrl
    }
    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.classList.remove('hidden')
    }
  }

  // Rotacionar imagem
  rotateLeft() {
    if (this.cropper) {
      this.cropper.rotate(-90)
    }
  }

  rotateRight() {
    if (this.cropper) {
      this.cropper.rotate(90)
    }
  }

  // Zoom
  zoomIn() {
    if (this.cropper) {
      this.cropper.zoom(0.1)
    }
  }

  zoomOut() {
    if (this.cropper) {
      this.cropper.zoom(-0.1)
    }
  }

  // Resetar posição
  reset() {
    if (this.cropper) {
      this.cropper.reset()
    }
  }

  // Remover foto existente
  removePhoto() {
    if (this.hasRemoveFlagTarget) {
      this.removeFlagTarget.checked = true
    }
    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.classList.add('hidden')
    }
    if (this.hasPreviewTarget) {
      this.previewTarget.src = ''
    }
    this.inputTarget.value = ''
  }
}
