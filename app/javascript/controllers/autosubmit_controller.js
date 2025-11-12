import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  submit(event) {
    const form = this.element.form || this.element.closest("form");
    if (form?.requestSubmit) form.requestSubmit();
    else form?.submit();
  }
}