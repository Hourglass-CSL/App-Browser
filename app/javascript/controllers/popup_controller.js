// app/javascript/controllers/popup_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "content", "panel"]
  static values = { menuUrl: String }

  connect() {
    this._inflight = null
    if (this.hasDialogTarget) this.hide()
  }

  async open() {

      if (this.hasContentTarget && this.contentTarget.dataset.prerendered === "true") {
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.setAttribute("aria-hidden", "false")
    const focusable = this.dialogTarget.querySelector(
      "[autofocus], [data-autofocus], button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])"
    )
    ;(focusable || this.dialogTarget).focus?.()
    return
  }
  
    if (!this.hasDialogTarget) return

    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.setAttribute("aria-hidden", "false")

    // spinner inicial SIEMPRE al abrir
    this.showSpinner()

    // intenta varias veces por si el blob aún no está adjunto
    await this.loadMenu({ tries: 8, delayMs: 900 })

    // enfoque accesible
    const focusable = this.dialogTarget.querySelector(
      "[autofocus], [data-autofocus], button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])"
    )
    ;(focusable || this.dialogTarget).focus?.()
  }

  close(e) {
    e?.preventDefault?.()
    if (!this.hasDialogTarget) return
    this.hide()
    this.element?.focus?.()
    this.abort()
  }

  hide() {
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.setAttribute("aria-hidden", "true")
  }

  clickOutside(e) {
    if (this.hasPanelTarget && this.panelTarget.contains(e.target)) return
    this.close(e)
  }

  preventClose(e) { e.stopPropagation() }

  // ---------- Carga del menú ----------
  async loadMenu({ tries = 5, delayMs = 800 } = {}) {
    this.abort()
    this._inflight = new AbortController()

    // Evita cachear respuestas intermedias
    const url = this.cacheBuster(this.menuUrlValue)

    try {
      const res = await fetch(url, {
        headers: { Accept: "application/json" },
        cache: "no-store",
        signal: this._inflight.signal
      })

      // Aún no hay archivo: mantenemos spinner y reintentamos
      if (res.status === 204) {
        if (tries > 0) {
          await this.sleep(delayMs)
          return this.loadMenu({ tries: tries - 1, delayMs })
        } else {
          return this.showStillProcessing()
        }
      }

      if (!res.ok) throw new Error(`HTTP ${res.status}`)

      // Esperamos JSON: { url, content_type }
      const { url: blobUrl, content_type: contentType } = await res.json()

      // Reemplaza el spinner por el contenido real
      this.contentTarget.innerHTML = ""

      if ((contentType || "").startsWith("image/")) {
        const img = document.createElement("img")
        img.src = this.cacheBuster(blobUrl)
        img.alt = "Menu"
        img.className = "max-w-[90vw] md:max-w-[70vw] max-h-[80vh] rounded-lg"
        this.contentTarget.appendChild(img)
      } else if (contentType === "application/pdf") {
        const iframe = document.createElement("iframe")
        iframe.src = `${this.cacheBuster(blobUrl)}#toolbar=0&navpanes=0`
        iframe.title = "Menu PDF"
        iframe.className = "w-[90vw] md:w-[70vw] h-[80vh] rounded-lg"
        this.contentTarget.appendChild(iframe)
      } else {
        // Fallback si no viene content_type
        const img = document.createElement("img")
        img.src = this.cacheBuster(blobUrl)
        img.alt = "Menu"
        img.className = "max-w-[90vw] md:max-w-[70vw] max-h-[80vh] rounded-lg"
        this.contentTarget.appendChild(img)
      }
    } catch (err) {
      if (err.name === "AbortError") return
      if (tries > 0) {
        await this.sleep(delayMs)
        return this.loadMenu({ tries: tries - 1, delayMs })
      }
      console.error("[popup] loadMenu error:", err)
      this.contentTarget.innerHTML =
        '<p class="text-sm text-red-400">No se pudo cargar el menú.</p>'
    } finally {
      this._inflight = null
    }
  }

  // ---------- Utilidades ----------
  showSpinner() {
    this.contentTarget.innerHTML =
      '<div class="w-64 h-64 bg-gray-700/40 rounded animate-pulse" data-popup-placeholder></div>'
  }

  showStillProcessing() {
    this.contentTarget.innerHTML =
      '<div class="text-center text-gray-300">' +
        '<div class="w-64 h-64 bg-gray-700/40 rounded animate-pulse mx-auto mb-3"></div>' +
        '<p>El menú está procesándose, intenta de nuevo en unos segundos…</p>' +
      '</div>'
  }

  abort() {
    if (this._inflight) {
      this._inflight.abort()
      this._inflight = null
    }
  }

  sleep(ms) { return new Promise(r => setTimeout(r, ms)) }

  cacheBuster(u) {
    try {
      const url = new URL(u, window.location.origin)
      url.searchParams.set("_", Date.now().toString())
      return url.toString()
    } catch {
      return u + (u.includes("?") ? "&" : "?") + "_=" + Date.now()
    }
  }
}
