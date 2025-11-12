
import { Controller } from "@hotwired/stimulus"

// Cross-fade "show N at a time"
export default class extends Controller {
  static targets = ["card"]
  static values = {
    size:     { type: Number, default: 2 },
    interval: { type: Number, default: 9000 },
    duration: { type: Number, default: 500 }   // ms de animación
  }

  connect() {
    // 🧠 Desactivar en pantallas móviles
    if (window.innerWidth < 768) {
      console.log("Rotator desactivado en mobile")
      return
    }

    this.currentGroup = 0

    // preparar tarjetas para transición
    this.cardTargets.forEach(c => this._primeCard(c))

    // mostrar primer grupo con fade-in
    this._showGroup(true)

    // rotación automática
    this._intervalId = setInterval(() => this.nextGroup(), this.intervalValue)

    // re-aplicar tras Turbo Streams (nuevas cards)
    this.observer = new MutationObserver(() => {
      requestAnimationFrame(() => {
        // preparar nuevas tarjetas
        this.cardTargets.forEach(c => this._primeCard(c))
        const totalGroups = Math.ceil(this.cardTargets.length / this.sizeValue)
        if (this.currentGroup >= totalGroups) this.currentGroup = 0
        this._showGroup(true)
      })
    })
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    clearInterval(this._intervalId)
    if (this.observer) this.observer.disconnect()
  }

  async nextGroup() {
    const total = Math.ceil(this.cardTargets.length / this.sizeValue)
    if (total <= 1) return

    const current = this._visibleCards()
    await Promise.all(current.map(c => this._fadeOut(c)))

    this.currentGroup = (this.currentGroup + 1) % total
    await this._showGroup(false)
  }

  // ——— helpers ———

  _groupRange() {
    const start = this.currentGroup * this.sizeValue
    const end   = start + this.sizeValue
    return [start, end]
  }

  _visibleCards() {
    return this.cardTargets.filter(c => !c.classList.contains("hidden"))
  }

  _primeCard(card) {
    card.style.transitionProperty = "opacity, transform"
    card.style.transitionDuration = `${this.durationValue}ms`
    card.style.transitionTimingFunction = "ease-in-out"
    card.style.transform = "translateY(0)"
    card.classList.add("opacity-0", "hidden")
  }

  async _showGroup(immediate = false) {
    const [start, end] = this._groupRange()
    const targets = this.cardTargets.slice(start, end)

    this.cardTargets.forEach(c => {
      if (!targets.includes(c)) {
        c.classList.add("opacity-0", "hidden")
      }
    })

    if (immediate) {
      targets.forEach(c => {
        c.classList.remove("hidden", "opacity-0")
      })
      return
    }

    await Promise.all(targets.map(c => this._fadeIn(c)))
  }

  _fadeIn(el) {
    return new Promise(resolve => {
      el.classList.remove("hidden")
      el.offsetHeight // reflow
      el.addEventListener("transitionend", resolve, { once: true })
      el.classList.remove("opacity-0")
    })
  }

  _fadeOut(el) {
    return new Promise(resolve => {
      el.addEventListener("transitionend", () => {
        el.classList.add("hidden")
        resolve()
      }, { once: true })
      el.classList.add("opacity-0")
    })
  }
}
