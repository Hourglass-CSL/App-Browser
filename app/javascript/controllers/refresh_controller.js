 
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:submit-end", this.refresh)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.refresh)
  }

  refresh(event) {
    if (event.detail.success) {
      window.location.reload()
    }
  }
}
