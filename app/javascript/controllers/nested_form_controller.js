import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "items"]

  connect() {
    this.nextIndex = Date.now()
  }

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, this.uniqueId())
    this.itemsTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-form-target='item']") ||
                 event.target.closest(".repeater-item")
    if (!item) return

    const destroyField = item.querySelector("input[name*='_destroy']")
    if (destroyField) {
      destroyField.value = "1"
      item.hidden = true
    } else {
      item.remove()
    }
  }

  uniqueId() {
    return this.nextIndex++
  }
}
