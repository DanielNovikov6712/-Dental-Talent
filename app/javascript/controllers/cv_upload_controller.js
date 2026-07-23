import { Controller } from "@hotwired/stimulus"

// Drag-and-drop CV upload: reflects the chosen file's name and enables the
// submit button. The <input type="file"> stays the source of truth so the form
// submits normally (progressive enhancement — it works without JS too).
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
