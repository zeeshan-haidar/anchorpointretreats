// app/javascript/controllers/mobile_menu_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "overlay"]

  connect() {
    this.open = false
  }

  toggle() {
    this.open = !this.open
    this.menuTarget.classList.toggle("active", this.open)
    this.overlayTarget.classList.toggle("active", this.open)
    document.body.classList.toggle("menu-open", this.open)
  }

  close() {
    this.open = false
    this.menuTarget.classList.remove("active")
    this.overlayTarget.classList.remove("active")
    document.body.classList.remove("menu-open")
  }
}
