import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
    document.body.classList.remove("overflow-hidden")
  }

  open(event) {
    const popupId = event.params.id
    const dialog = this.dialogTargets.find((el) => el.id === popupId)

    if (!dialog) return

    this.closeAll()

    dialog.classList.remove("hidden")
    dialog.classList.add("flex")
    dialog.setAttribute("aria-hidden", "false")

    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this.boundHandleEscape)

    window.dispatchEvent(new CustomEvent("staff:popup-opened"))
  }

  close(event) {
    const dialog =
      event?.currentTarget?.closest("[data-staff-popup-target='dialog']") ||
      this.currentDialog()

    if (!dialog) return

    dialog.classList.add("hidden")
    dialog.classList.remove("flex")
    dialog.setAttribute("aria-hidden", "true")

    if (!this.currentDialog()) {
      document.body.classList.remove("overflow-hidden")
      document.removeEventListener("keydown", this.boundHandleEscape)
      window.dispatchEvent(new CustomEvent("staff:popup-closed"))
    }
  }

  clickOutside(event) {
    if (event.target === event.currentTarget) {
      this.close(event)
    }
  }

  preventClose(event) {
    event.stopPropagation()
  }

  closeAll() {
    this.dialogTargets.forEach((dialog) => {
      dialog.classList.add("hidden")
      dialog.classList.remove("flex")
      dialog.setAttribute("aria-hidden", "true")
    })
  }

  currentDialog() {
    return this.dialogTargets.find((dialog) => !dialog.classList.contains("hidden"))
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}