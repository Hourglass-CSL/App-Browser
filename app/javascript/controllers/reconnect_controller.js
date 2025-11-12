import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("[Reconnect] Dispatching carousel:reconnect");
    this.element.dispatchEvent(new CustomEvent("carousel:reconnect", { bubbles: true }))
  }
}