import { Controller } from "@hotwired/stimulus"

// Add/remove rows for the education, work-experience and language repeaters.
// New rows are cloned from a <template> whose fields use a NEW_RECORD index
// placeholder; existing rows are soft-deleted via their hidden _destroy field
// so Rails' accepts_nested_attributes_for removes them on save.
export default class extends Controller {
  static targets = ["template", "items"]

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
    return `${Date.now()}${Math.floor(Math.random() * 1000)}`
  }
}
