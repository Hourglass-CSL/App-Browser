import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 6000 },
    targetSelector: String
  }

  connect() {
    this.wrapper = this.element
    this.idx     = 0
    this.timer   = null

    this.start()
    this.setupEvents()

    // watch for ANY added/removed cards under the wrapper
    this.observer = new MutationObserver(() => this.reinitialize())
    this.observer.observe(this.wrapper, {
      childList: true,
      subtree:   true
    })

    console.log("[Carousel] connected and observing entire wrapper")
  }

  disconnect() {
    this.stop()
    this.observer.disconnect()
  }

  cards() {
    return this.wrapper.querySelectorAll(this.targetSelectorValue || ".flex-none")
  }

  cardWidth() {
    const c = this.cards()[0]
    if (!c) return 0
    const style = getComputedStyle(c)
    return c.offsetWidth + parseInt(style.marginRight)
  }

  scrollTo(i) {
    this.wrapper.scrollTo({
      left: i * this.cardWidth(),
      behavior: "smooth"
    })
  }

  // → actually advance the index and scroll
  step = () => {
    const list = this.cards()
    if (list.length < 2) return
    this.idx = (this.idx + 1) % list.length
    this.scrollTo(this.idx)
  }

  start() {
    this.stop()
    if (this.cards().length < 2) return
    // use the full delayValue (no division by count)
    this.timer = setInterval(this.step, this.delayValue)
  }

  stop() {
    clearInterval(this.timer)
  }

  reinitialize() {
    console.log("[Carousel] reinitializing – found", this.cards().length, "cards")
    this.idx = 0
    this.start()
  }

  setupEvents() {
    this.wrapper.addEventListener("mouseover", () => this.stop())
    this.wrapper.addEventListener("mouseout",  () => this.start())
  }
}
