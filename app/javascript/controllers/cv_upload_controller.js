import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "filename", "dropzone", "submit"]

  connect() {
    this.refresh()
  }

  refresh() {
    const file = this.inputTarget.files[0]
    if (file) {
      this.filenameTarget.textContent = file.name
      if (this.hasSubmitTarget) this.submitTarget.disabled = false
    } else {
      this.filenameTarget.textContent = ""
      if (this.hasSubmitTarget) this.submitTarget.disabled = true
    }
  }

  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("is-dragover")
  }

  dragleave() {
    this.dropzoneTarget.classList.remove("is-dragover")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("is-dragover")
    if (event.dataTransfer.files.length) {
      this.inputTarget.files = event.dataTransfer.files
      this.refresh()
    }
  }
}
