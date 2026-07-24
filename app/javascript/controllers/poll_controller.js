import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fallback"]
  static values = {
    url: String,
    interval: { type: Number, default: 1500 },
    maxAttempts: { type: Number, default: 20 }
  }

  connect() {
    this.attempts = 0
    this.timer = setInterval(() => this.check(), this.intervalValue)
  }

  disconnect() {
    this.stop()
  }

  async check() {
    this.attempts += 1
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (response.ok) {
        const data = await response.json()
        if (data.finished) {
          this.stop()
          window.location.assign(data.redirect_url)
          return
        }
      }
    } catch (_error) {
    }

    if (this.attempts >= this.maxAttemptsValue) {
      this.stop()
      if (this.hasFallbackTarget) this.fallbackTarget.hidden = false
    }
  }

  stop() {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }
}
