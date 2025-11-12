// app/javascript/controllers/clock_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time", "date"]

  connect() {
    this.updateDate()
    this.updateTime()
    this.timer = setInterval(() => this.updateTime(), 1000)
    this.dateTimer = setInterval(() => this.updateDate(), 60 * 1000)
  }

  disconnect() {
    clearInterval(this.timer)
    clearInterval(this.dateTimer)
  }

  updateDate() {
    const opts = {
      weekday: "long",
      year:    "numeric",
      month:   "long",
      day:     "numeric"
    }
    // Usa el locale de la ventana (Rails)
    const locale = window.APP_LOCALE || "en"
    this.dateTarget.textContent = new Date().toLocaleDateString(locale, opts)
  }

  updateTime() {
    const opts = { hour: "2-digit", minute: "2-digit", second: "2-digit" }
    const locale = window.APP_LOCALE || "en"
    this.timeTarget.textContent = new Date().toLocaleTimeString(locale, opts)
  }
}
